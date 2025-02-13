/**
 Copyright (c) FingerprintJS, Inc, 2021 (https://fingerprintjs.com)
 */

#if !os(macOS)
    import UIKit
    import WebKit

    public protocol FingerprintJSPro {
        typealias VisitorIdHandler = (Result<VisitorId, Swift.Error>) -> Void

        func getVisitorId(_ handler: @escaping VisitorIdHandler)
    }

    public extension FingerprintJSPro {
        typealias Factory = FingerprintJSProFactory
        typealias VisitorId = String
    }

    public enum FingerprintJSProFactory {
        public static func getInstance(token: String, endpoint: URL? = nil, region: String? = nil) -> FingerprintJSPro {
            return FingerprintJSProImpl(token: token, endpoint: endpoint, region: region)
        }
    }

    internal enum Error: LocalizedError, CustomStringConvertible {
        case `internal`
        case message(String)

        // MARK: - Public

        public var errorDescription: String? {
            description
        }

        // MARK: - Internal

        var description: String {
            switch self {
            case .internal:
                return "Unknown error"
            case let .message(text):
                return text
            }
        }
    }

    private struct Settings {
        internal struct InitializationArguments: Codable {
            let token: String
            let endpoint: URL?
            let region: String?
        }

        internal struct RequestParameters: Codable {
            internal struct Tags: Codable {
                let deviceId: String?
                let deviceType: String?
            }

            // MARK: - Internal

            internal let tags: Tags?
        }

        // MARK: - Internal

        internal var initializationArguments: InitializationArguments
        internal var requestParameters: RequestParameters
    }

    // MARK: - Private

    private final class FingerprintJSProImpl: NSObject, FingerprintJSPro, WKNavigationDelegate, WKScriptMessageHandler {
        // MARK: - Lifecycle

        public init(token: String, endpoint: URL? = nil, region: String? = nil) {
            settings = Settings(initializationArguments: .init(token: token,
                                                               endpoint: endpoint,
                                                               region: region),
                                requestParameters: .init(tags: .init(deviceId: Self.getIdentifierForVendor(),
                                                                     deviceType: "ios")))

            super.init()
        }

        // MARK: - Public

        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            do {
                guard message.name == messageHandlerName
                else {
                    throw Error.internal
                }

                guard let body = message.body as? [String: Any] else {
                    throw Error.internal
                }

                if let visitorId = body["success"] as? String {
                    handler?(.success(visitorId))
                } else if let error = body["error"] as? String {
                    throw Error.message(error)
                } else {
                    throw Error.internal
                }

            } catch {
                handler?(.failure(error))
            }
        }

        public func getVisitorId(_ handler: @escaping VisitorIdHandler) {
            do {
                guard let scriptString = Bundle.module.url(forResource: "fp.min", withExtension: "js")
                    .map({ $0.path })
                    .flatMap(FileManager.default.contents)?
                    .flatMap({ String(data: $0, encoding: .utf8) })
                else {
                    throw Error.internal
                }

                let parametersString = try settings.requestParameters.makeJSONString()
                let argumentsString = try settings.initializationArguments.makeJSONString()
                let messageHandler = "window.webkit.messageHandlers.\(messageHandlerName)"

                let html: String =
                    """
                    <html><body><script>
                     var FingerprintJS = \(scriptString);
                     FingerprintJS.load(\(argumentsString))
                            .then(fp => fp.get(\(parametersString)))
                            .then(result => \(messageHandler).postMessage({ success: result.visitorId }))
                            .catch(e => \(messageHandler).postMessage({ error: e.message }));
                    </script></body></html>
                    """

                self.handler = {
                    self.webView = nil
                    self.handler = nil

                    handler($0)
                }

                guard let vc = UIApplication.shared.keyWindow?.rootViewController else {
                    throw Error.message("UIApplication.shared.keyWindow.rootViewController must be loaded before use `getVisitorId` method")
                }

                DispatchQueue.main.async {
                    self.webView = self.makeWebView(in: vc)
                    self.webView?.loadHTMLString(html, baseURL: self.settings.initializationArguments.endpoint)
                }

            } catch {
                handler(.failure(error))
            }
        }

        // MARK: - Internal

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Swift.Error) {
            handler?(.failure(error))
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Swift.Error) {
            handler?(.failure(error))
        }

        // MARK: - Private

        private let settings: Settings

        private var handler: VisitorIdHandler?

        private lazy var messageHandlerName: String = {
            UUID().uuidString
                .components(separatedBy: .letters.inverted)
                .joined()
        }()

        private var webView: WKWebView? {
            didSet {
                oldValue?.removeFromSuperview()
                oldValue?.configuration.userContentController.removeScriptMessageHandler(forName: messageHandlerName)
            }
        }

        private static func getIdentifierForVendor() -> String? {
            let account = defaultAccount(for: "identifierForVendor")

            if let data = try? Keychain.readKey(account: account),
               let id = String(data: data, encoding: .utf8)
            {
                return id
            } else if let id = UIDevice.current.identifierForVendor?.uuidString,
                      let data = id.data(using: .utf8)
            {
                try? Keychain.storeKey(data, account: account)
                return id
            }
            return nil
        }

        private func makeWebView(in viewController: UIViewController) -> WKWebView {
            let config = WKWebViewConfiguration()
            config.userContentController.add(self, name: messageHandlerName)

            let webView = WKWebView(frame: .init(x: 1, y: 1, width: 0, height: 0), configuration: config)
            webView.translatesAutoresizingMaskIntoConstraints = false

            viewController.view.addSubview(webView)

            return webView
        }
    }

    private extension Encodable {
        func makeJSONString() throws -> String {
            let encoder = JSONEncoder()

            let data = try encoder.encode(self)

            if let result = String(data: data, encoding: .utf8) {
                return result
            } else {
                throw Error.internal
            }
        }
    }

    #if !SWIFT_PACKAGE
        extension Bundle {
            static var module: Bundle {
                Bundle(for: FingerprintJSProImpl.self)
            }
        }
    #endif

#endif
