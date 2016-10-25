# JavaScript Transfer Protocol 

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/JSTPMobile/iOS/jstp-new/LICENSE) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![Cocoapods compatible](https://img.shields.io/badge/Cocoapods-compatible-brightgreen.svg)](http://cocoapods.org)

JSTP is a data transfer protocol that uses JavaScript objects syntax as the encoding format and supports metadata. This implementation currently supports this types of packet:

- [x] handshake — protocol handshake
- [x] callback — remote API response
- [x] inspect — API introspection request
- [ ] stream — data streaming
- [ ] health — system data about resource state and usage
- [x] event — event with attached data
- [ ] state — data synchronization
- [x] call — remote API call

## Example

First thing is to import the framework. See the Installation instructions on how to add the framework to your project.

```swift
import JSTP
```

Once imported, you can open a connection to your JSTP server. Note that `connection` is probably best as a property, so it doesn't get deallocated right after being setup.

```swift

connection = Connection(host: "0.0.0.0", port: 6969, secure: false)
connection.delegate = self
connection.connect()
```

After you are connected, there are some optional delegate methods you may want to implement.

#### `connectionDidConnect`

This method is called as soon as the client connects to the server.

```swift
func connectionDidConnect(_ connection: Connection) {
   print("Connected")
}
```

#### `connectionDidDisconnect`

This method is called as soon as the client is disconnected from the server.

```swift
func connectionDidDisconnect(_ connection: Connection) {
   print("Disconnected")
}
```

#### `connectionDidFailWithError`

This method is called as soon as some error occurs.

```swift
func connection(_ connection: Connection, didFailWithError error: NSError)
   print("Error \(error.localizedDescription)")
}
```

#### `connectionDidReceiveEvent`

This method is called as soon as the client receives some event.

```swift
func connection(_ connection: Connection, didReceiveEvent  event: Event) { {
   print("Event")
}
```

Event is simple class.

```swift
class Event {
   let arguments: Any
   let interface: String
   let name: String
}
```

## Requirements

Framework works with iOS 7 or above. It is recommended to use iOS 8 or above for CocoaPods/framework support. To use it with a project targeting iOS 7, you must include all Swift files directly in your project.

## Installation

### Carthage

Check out the [Carthage](https://github.com/Carthage/Carthage) docs on how to add a install. The `JSTP` framework is already setup with shared schemes. To integrate JSTP into your Xcode project using Carthage, specify it in your `Cartfile`:

```
github "JSTPMobile/iOS"
```

Run `carthage update`, and you should now have the latest version of JSTP in your Carthage folder.

### Cocoapods

Check out [Get Started](http://cocoapods.org/) tab on [cocoapods.org](http://cocoapods.org/).

To use `JSTP` in your project add the following `Podfile` to your project

```
pod 'JSTP', :git => 'https://github.com/JSTPMobile/iOS.git', :submodules => true
```

Then run:

```
pod install
```

### Other

Simply grab the framework (either via git submodule or another package manager).

Add the `JSTP.xcodeproj` to your Xcode project. Once that is complete, in your "Build Phases" add the `JSTP.framework` to your "Link Binary with Libraries" phase.

## License

JSTP is licensed under the MIT License.
