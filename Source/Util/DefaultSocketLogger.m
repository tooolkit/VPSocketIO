//
//  DefaultSocketLogger.m
//  IFMSocketIO
//
//  Created by yangguang on 2018/7/23.
//  Copyright © 2018年 bngj. All rights reserved.
//

#import "DefaultSocketLogger.h"

@implementation DefaultSocketLogger

static VPSocketLogger *logInstance;

+(void)setLogger:(VPSocketLogger*)newLogger {
    logInstance = newLogger;
}

+(VPSocketLogger*)logger {
    return logInstance;
}

@end
