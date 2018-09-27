//
//  VPSocketIOClient.h
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/24.
//  Copyright © 2018年 bngj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VPSocketAnyEvent.h"
#import "VPSocketIOClientProtocol.h"
@class VPSocketManager;

typedef enum : NSUInteger {
    /// Called when the client connects. This is also called on a successful reconnection. A connect event gets one
    VPSocketClientEventConnect = 0x0,
    /// Called when the socket has disconnected and will not attempt to try to reconnect.
    VPSocketClientEventDisconnect,
    /// Called when an error occurs.
    VPSocketClientEventError,
    
    VPSocketClientEventPing,
    
    VPSocketClientEventPong,
    /// Called when the client begins the reconnection process.
    VPSocketClientEventReconnect,
    /// Called each time the client tries to reconnect to the server.
    VPSocketClientEventReconnectAttempt,
    /// Called every time there is a change in the client's status.
    VPSocketClientEventStatusChange,
} VPSocketClientEvent;


@interface VPSocketIOClient : NSObject<VPSocketIOClientProtocol>
@property (nonatomic, strong, readonly) NSString *ssid;
@property (nonatomic, strong) VPSocketAckManager *ackHandlers;


- (instancetype)initWith:(VPSocketManager *)manager namesp:(NSString *)namesp;
- (void)setReconnecting:(NSString *)reason;

//Test properties
- (NSArray *)testHandlers;
- (void)setTestable;
- (void)setTestStatus:(VPSocketIOClientStatus)status;
- (void)emitTest:(NSString *)event data:(id)data;

- (NSInteger)currentAck;

@end
