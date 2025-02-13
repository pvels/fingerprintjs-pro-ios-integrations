<p align="center">
  <a href="https://fingerprintjs.com">
    <img src="https://user-images.githubusercontent.com/10922372/129346814-a4e95dbf-cd27-49aa-ae7c-f23dae63b792.png" alt="FingerprintJS" width="312px" />
  </a>
</p>
<p align="center">
  <a href="https://discord.gg/39EpE2neBg">
    <img src="https://img.shields.io/discord/852099967190433792?style=logo&label=Discord&logo=Discord&logoColor=white" alt="Discord server">
  </a>
</p>

# [FingerprintJS Pro](https://fingerprintjs.com/) iOS Integrations

An example app and packages demonstrating [FingerprintJS Pro](https://fingerprintjs.com/) capabilities on the iOS platform. The repository illustrates how to retrieve a FingerprintJS Pro visitor identifier in a native mobile app. These integrations communicate with the FingerprintJS Pro API and require [browser token](https://dev.fingerprintjs.com/docs). If you are interested in the Android platform, you can also check our [FingerprintJS Pro Android integrations](https://github.com/fingerprintjs/fingerprintjs-pro-android-webview).

There are two typical use cases:
- Using our native library to retrieve a FingerprintJS Pro visitor identifier in the native code OR
- Retrieving visitor identifier using signals from the FingerprintJS Pro browser agent in the webview on the JavaScript level combined with vendor identifier.

## Using the external library to retrieve a FingerprintJS Pro visitor identifier
This integration approach uses our library [fpjs-ios-wv](https://github.com/fingerprintjs/fingerprintjs-pro-ios-webview/tree/master/fpjs-ios-wv). It collects various signals from the iOS system, sends them to the FingerprintJS Pro API for processing, and retrieves an accurate visitor identifier.

### 1. Installation

#### CocoaPods

Specify the following dependency in your `Podfile`:

```ruby
pod 'FingerprintJSPro', '~> 0.1.1'
```

#### Swift Package Manager

Add the following dependency to your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/fingerprintjs/fingerprintjs-pro-ios-integrations", .upToNextMajor(from: "0.1.0"))
]
```

### 2. Import

```swift
import FingerprintJSPro
```

### 3. Get the visitor identifier
You can find your [browser api token](https://dev.fingerprintjs.com/docs) in your [dashboard](https://dashboard.fingerprintjs.com/subscriptions/).

```swift
FingerprintJSPro.Factory
    .getInstance(
        token: "your-browser-token", // required
        endpoint: URL(string: "https://fp.yourdomain.com"), // default: nil, optional: true
        region: nil // default: nil, optional: true ("eu" for europe, nil for global)
    )
    .getVisitorId { result in
        switch result {
        case let .failure(error):
            print("Error: ", error.localizedDescription)
        case let .success(visitorId):
            print("Success: ", visitorId)
        }
    }
```

## Using inside a webview with JavaScript
This approach uses signals from [FingerprintJS Pro browser agent](https://dev.fingerprintjs.com/docs/quick-start-guide#js-agent) together with iOS device [vendor identifier](https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor). The vendor identifier is added to the [`tag` field](https://dev.fingerprintjs.com/docs#tagging-your-requests) in the given format. FingerprintJS Pro browser agent adds an additional set of signals and sents them to the FingerprintJS Pro API. Eventually, the API returns accurate visitor identifier.

### 1. Add a JavaScript interface to your webview

```swift
let vendorId = UIDevice.current.identifierForVendor?.uuidString ?? "undefined"

let script = WKUserScript(source: "window.fingerprintjs.vendorId = \(vendorId)",
                          injectionTime: .atDocumentStart,
                          forMainFrameOnly: false)

webView.configuration.userContentController.addUserScript(script)

```

### 2. Setup the JavaScript FingerprintJS Pro integration in your webview

```js
function initFingerprintJS() {
  // Initialize an agent at application startup.
  const fpPromise = FingerprintJS.load({
    token: "your-browser-token",
    endpoint: "your-endpoint", // optional
    region: "your-region", // optional
  });

  // Get the visitor identifier when you need it.
  fpPromise
    .then((fp) =>
      fp.get({
        tag: {
          deviceId: window.fingerprintjs.vendorId, // use vendor ID as device ID
          deviceType: "ios",
        },
      })
    )
    .then((result) => console.log(result.visitorId));
}
```
You can find your [browser token](https://dev.fingerprintjs.com/docs) in your [dashboard](https://dashboard.fingerprintjs.com/subscriptions/).

## Additional Resources
[FingerprintJS Pro documentation](https://dev.fingerprintjs.com/docs)

## License
This library is MIT licensed.
