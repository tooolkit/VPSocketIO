//
//  VPSocketManager.h
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/24.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VPSocketManagerProtocol.h"
@class VPSocketIOClient;
@interface VPSocketManager : NSObject<VPSocketManagerProtocol>

- (instancetype)initWithURL:(NSURL *)socketURL
                     config:(NSDictionary *)config;

- (VPSocketIOClientStatus)status;
- (VPSocketPacket *)parseSocketMessage:(NSString *)msg;
- (VPSocketPacket *)parseString:(NSString *)message;

//test
- (void)setTestStatus:(VPSocketIOClientStatus)status;

@end
