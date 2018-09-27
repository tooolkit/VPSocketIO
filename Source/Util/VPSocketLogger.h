//
//  BISocketLogger.h
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/23.
//  Copyright © 2018年 bngj. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VPSocketLogger : NSObject

@property (nonatomic) BOOL log;

-(void) log:(NSString*)message type:(NSString*)type;
-(void) error:(NSString*)message type:(NSString*)type;

@end
