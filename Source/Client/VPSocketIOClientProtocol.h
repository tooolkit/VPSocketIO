//
//  VPSocketIOClientProtocol.h
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/24.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#ifndef VPSocketIOClientProtocol_h
#define VPSocketIOClientProtocol_h

#import <Foundation/Foundation.h>
@class VPSocketAckManager;
@class VPSocketAckEmitter;
@class VPSocketManager;
@class VPSocketAnyEvent;
@class VPSocketEventHandler;
@class VPSocketOnAckCallback;
@class VPSocketPacket;

typedef enum : NSUInteger {
    VPSocketIOClientStatusNotConnected = 0x1,
    VPSocketIOClientStatusDisconnected = 0x2,
    VPSocketIOClientStatusConnecting = 0x3,
    VPSocketIOClientStatusOpened = 0x4,
    VPSocketIOClientStatusConnected = 0x5
} VPSocketIOClientStatus;

typedef void (^VPSocketAnyEventHandler)(VPSocketAnyEvent*event);
typedef void (^VPSocketIOVoidHandler)(void);


typedef void (^VPScoketAckArrayCallback)(NSArray*array);
typedef void (^VPSocketOnEventCallback)(NSArray*array, VPSocketAckEmitter*emitter);

@protocol VPSocketIOClientProtocol <NSObject>

@required

@property (nonatomic, copy) VPSocketAnyEventHandler anyHandler;
@property (nonatomic, strong, readonly) NSMutableArray<VPSocketEventHandler*>* handlers;
@property (nonatomic, weak) VPSocketManager *manager;
@property (nonatomic, strong, readonly) NSString *nsp;
@property (nonatomic, readonly) VPSocketIOClientStatus status;


- (void)connect;

- (void)connectWithTimeoutAfter:(double)timeout
                    withHandler:(VPSocketIOVoidHandler)handler;

-(void) didConnect:(NSString*) namespace;

-(void) didDisconnect:(NSString*)reason;

-(void)didError:(NSString*)reason;

-(void) disconnect;

-(void)emit:(NSString*)event items:(NSArray*)items;

- (void)emit:(NSArray *)items ack:(NSInteger)ack binary:(BOOL)binary isAck:(BOOL)isAck;

-(void)emitAck:(NSInteger)ack withItems:(NSArray*)items;

-(VPSocketOnAckCallback*) emitWithAck:(NSString*)event items:(NSArray*)items;

-(void) handleAck:(int)ack withData:(NSArray*)data;

-(void) handleClientEvent:(NSString*)event withData:(NSArray*) data;

-(void)handleEvent:(NSString*)event
          withData:(NSArray*) data
 isInternalMessage:(BOOL)internalMessage
           withAck:(int)ack;

-(void)handlePacket:(VPSocketPacket*) packet;

-(void)leaveNamespace;

-(void)joinNamespace;

-(void)off:(NSString*) event;

-(void)offWithID:(NSUUID*)UUID;

-(NSUUID*)on:(NSString*)event callback:(VPSocketOnEventCallback) callback;

-(NSUUID*)once:(NSString*)event callback:(VPSocketOnEventCallback) callback;

-(void)onAny:(VPSocketAnyEventHandler)handler;

-(void)removeAllHandlers;

-(void)tryReconnect:(NSString*)reason;

@end


#endif /* VPSocketIOClientProtocol_h */
