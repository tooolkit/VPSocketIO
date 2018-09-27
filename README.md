# VPSocketIO
Socket.IO client for iOS. Supports socket.io 2.0+

It's based on a official Swift library from here: [SocketIO-Client-Swift](https://github.com/socketio/socket.io-client-swift)

It uses Jetfire [Jetfire](https://github.com/acmacalister/jetfire)

## Objective-C Example
```objective-c
#import <SocketIO-iOS/SocketIO-iOS.h>;
NSString *urlString = @"http://localhost:8080";
NSURL *url = [[NSURL alloc]initWithString:urlString];
self.manager = [[VPSocketManager alloc]initWithURL:url config:@{@"log":@(NO)}];
//    self.socket = [self.manager defaultSocket];
self.socket = [self.manager socketFor:@"/web"];
[self.socket on:@"connect" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
NSLog(@"%@",array);
}];
[self.socket connect];


```

## Features
- Supports socket.io 2.0+
- Supports binary
- Supports Polling and WebSockets
- Supports TLS/SSL

## Installation

### Carthage
Add these line to your `Cartfile`:
```
github "vascome/vpsocketio" ~> 1.0.5 # Or latest version
```

Run `carthage update --platform ios,macosx`.

### CocoaPods 1.0.0 or later
Create `Podfile` and add `pod 'VPSocketIO'` (pod files are case sensetive):

```ruby

target 'MyApp' do
    pod 'VPSocketIO', '~> 1.0.5' # Or latest version
end
```

## License
MIT

