//
//  VPSocketManagerProtocol.h
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/24.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import "VPSocketEngine.h"
#import "VPSocketIOClient.h"

@protocol VPSocketManagerProtocol<NSObject, VPSocketEngineClient>

@required

@property (nonatomic, strong, readonly) VPSocketIOClient *defaultSocket;

@property (nonatomic, strong) id<VPSocketEngineProtocol> engine;

@property (nonatomic) BOOL forceNew;

@property (nonatomic, strong, readonly) dispatch_queue_t handleQueue;

@property (nonatomic, strong) NSMutableDictionary<NSString *, VPSocketIOClient*> *nsps;

@property (nonatomic) BOOL reconnects;

@property (nonatomic) NSInteger reconnectWait;

@property (nonatomic, strong, readonly) NSURL *socketURL;

@property (nonatomic) VPSocketIOClientStatus status;

- (void)connect;

- (void)connectSocket:(VPSocketIOClient *)socket;

- (void)didDisconnect:(NSString *)reason;

- (void)disconnect;

- (void)disconnectSocket:(VPSocketIOClient *)socket;

- (void)disconnectSocketFor:(NSString *)nsp;

//for open func emitAll(_ event: String, withItems items: [Any])
- (void)emitAll:(NSString *)event withItems:(NSArray *)items;

- (void)reconnect;

- (VPSocketIOClient *)removeSocket:(VPSocketIOClient *)socket;

- (VPSocketIOClient *)socketFor:(NSString *)nsp;

@end
