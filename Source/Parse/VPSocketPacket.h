//
//  VPSocketPacket.h
//  VPSocketIO
//
//  Created by Vasily Popov on 9/19/17.
//  Copyright © 2017 Vasily Popov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    VPPacketTypeConnect = 0,
    VPPacketTypeDisconnect,
    VPPacketTypeEvent,
    VPPacketTypeAck,
    VPPacketTypeError,
    VPPacketTypeBinaryEvent,
    VPPacketTypeBinaryAck
    
} VPPacketType;

@interface VPSocketPacket : NSObject

@property (nonatomic, strong, readonly) NSString *packetString;
@property (nonatomic, strong, readonly) NSMutableArray<NSData*> *binary;
@property (nonatomic, readonly) VPPacketType type;
@property (nonatomic, readonly) NSInteger id;
@property (nonatomic, strong, readonly) NSString *event;
@property (nonatomic, strong, readonly) NSArray *args;
@property (nonatomic, strong, readonly) NSString *nsp;
@property (nonatomic, strong, readonly) NSMutableArray *data;

-(instancetype)init:(VPPacketType)type
                nsp:(NSString*)namespace
       placeholders:(NSInteger)plholders;

-(instancetype)init:(VPPacketType)type
               data:(NSArray*)data
                 id:(NSInteger)id
                nsp:(NSString*)nsp
       placeholders:(NSInteger)plholders
             binary:(NSArray*)binary;

//checkForBinary defaults true
+(VPSocketPacket*)packetFromEmit:(NSArray*)items id:(NSInteger)id nsp:(NSString*)nsp ack:(BOOL)ack checkForBinary:(BOOL)checkForBinary;

-(BOOL)addData:(NSData*)data;

@end
