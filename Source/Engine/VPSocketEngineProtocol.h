//
//  VPSocketEngineProtocol.h
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/23.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VPSocketEngineClient<NSObject>

@required

/// Called when the engine errors.
-(void)engineDidError:(NSString*)reason;
/// Called when the engine opens.
-(void)engineDidOpen:(NSString*)reason;
/// Called when the engine closes.
-(void)engineDidClose:(NSString*)reason;
/// Called when the engine has a message that must be parsed.
-(void)parseEngineMessage:(NSString*)msg;
/// Called when the engine receives binary data.
-(void)parseEngineBinaryData:(NSData*)data;

-(void)engineDidReceivePong;
-(void)engineDidSendPing;

@end

@protocol VPSocketEngineProtocol<NSObject>

@required
@property (nonatomic, weak) id<VPSocketEngineClient> client;
@property (nonatomic, readonly) BOOL closed;
@property (nonatomic, readonly) BOOL connected;

/// Starts the connection to the server.
-(void)connect;
/// Disconnects from the server.
-(void)disconnect:(NSString*)reason;
// reset client
-(void)syncResetClient;

-(void)send:(NSString*)msg withData:(NSArray<NSData*>*) data;

@end
