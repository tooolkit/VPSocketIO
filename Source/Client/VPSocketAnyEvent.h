//
//  VPSocketAnyEvent.h
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/24.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VPSocketIOClientProtocol.h"

@interface VPSocketAnyEvent : NSObject

@property (nonatomic, strong, readonly) NSString* event;
@property (nonatomic, strong, readonly) NSArray *items;

-(instancetype)initWithEvent:(NSString*)event andItems:(NSArray*)items;

@end

@interface VPSocketEventHandler : NSObject

@property (nonatomic, strong, readonly) NSString *event;
@property (nonatomic, strong, readonly) NSUUID *uuid;
@property (nonatomic, strong, readonly) VPSocketOnEventCallback callback;
-(instancetype)initWithEvent:(NSString*)event uuid:(NSUUID*)uuid andCallback:(VPSocketOnEventCallback)callback;
-(void)executeCallbackWith:(NSArray*)items withAck:(int)ack withSocket:(id<VPSocketIOClientProtocol>)socket;
@end
