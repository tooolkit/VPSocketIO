//
//  VPSocketNamespacePacketTest.m
//  VPIFMSocketIOTests
//
//  Created by yangguang on 2018/7/30.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VPSocketManager.h"
#import "VPSocketPacket.h"

@interface VPSocketNamespacePacketTest : XCTestCase
@property (nonatomic, strong) VPSocketManager *parser;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSData *data2;
@end

@implementation VPSocketNamespacePacketTest

- (void)setUp {
    [super setUp];
    self.parser = [[VPSocketManager alloc]initWithURL:[NSURL URLWithString:@"http://localhost"] config:@{}];
    self.data = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    self.data2 = [@"test2" dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testEmptyEmit {
    NSArray *sendData = @[@"test"];
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/swift" ack:false checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeEvent);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testNullEmit {
    NSArray *sendData = @[@"test", [NSNull null]];
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/swift" ack:false checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeEvent);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testStringEmit {
    NSArray *sendData = @[@"test", @"foo bar"];
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/swift" ack:false checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeEvent);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testJSONEmit {
    NSArray *sendData = @[@"test", @{@"foobar":@YES, @"hello":@1, @"test":@"hello", @"null":[NSNull null]}];
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/swift" ack:false checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeEvent);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testArrayEmit {
    NSArray *sendData = @[@"test", @[@"hello", @1, @{@"test":@"test"}]];
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/swift" ack:false checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeEvent);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testBinaryEmit {
    NSArray *sendData = @[@"test", self.data];
    VPSocketPacket *packet = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/swift" ack:false checkForBinary:YES];
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packet.packetString];
    XCTAssertEqual(parsed.type, VPPacketTypeBinaryEvent);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    XCTAssertTrue([self compareAnyArray:packet.binary expected:@[self.data]]);
    NSArray *array = @[@"test", @{@"_placeholder":@YES,@"num":@0}];
    XCTAssertTrue([self compareAnyArray:parsed.data expected:array]);
}

- (void)testMultipleBinaryEmit {
    NSArray *sendData = @[@"test", @{
                              @"data1":self.data,
                              @"data2":self.data2
                              }];
    VPSocketPacket *packet = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/swift" ack:false checkForBinary:YES];
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packet.packetString];
    
    XCTAssertEqual(parsed.type, VPPacketTypeBinaryEvent);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    NSDictionary<NSString *, id> *binaryObj = parsed.data[1];
    NSInteger data1Loc = [binaryObj[@"data1"][@"num"] integerValue];
    NSInteger data2Loc = [binaryObj[@"data2"][@"num"] integerValue];
    
    XCTAssertEqual(packet.binary[data1Loc], self.data);
    XCTAssertEqual(packet.binary[data2Loc], self.data2);
}

- (void)testEmitWithAck {
    NSArray *sendData = @[@"test"];
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:0 nsp:@"/swift" ack:false checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeEvent);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    XCTAssertEqual(parsed.id, 0);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testEmitDataWithAck {
    NSArray *sendData = @[@"test", self.data];
    VPSocketPacket *packet = [VPSocketPacket packetFromEmit:sendData id:0 nsp:@"/swift" ack:false checkForBinary:YES];
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packet.packetString];
    XCTAssertEqual(parsed.type, VPPacketTypeBinaryEvent);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    XCTAssertEqual(parsed.id, 0);
    NSArray *array = @[@"test", @{@"_placeholder":@YES,@"num":@0}];
    XCTAssertTrue([self compareAnyArray:parsed.data expected:array]);
    XCTAssertTrue([self compareAnyArray:packet.binary expected:@[self.data]]);
}

- (void)testEmptyAck {
    NSString *packetStr = [VPSocketPacket packetFromEmit:@[] id:0 nsp:@"/swift" ack:true checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeAck);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    XCTAssertEqual(parsed.id, 0);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:@[]]);
}

- (void)testNullAck {
    NSArray *sendData = @[[NSNull null]];
    
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:0 nsp:@"/swift" ack:true checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeAck);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    XCTAssertEqual(parsed.id, 0);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testStringAck {
    NSArray *sendData = @[@"test"];
    
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:0 nsp:@"/swift" ack:true checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeAck);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    XCTAssertEqual(parsed.id, 0);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testJSONAck {
    NSArray *sendData = @[@"test", @{@"foobar":@YES, @"hello":@1, @"test":@"hello", @"null":[NSNull null]}];
    
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:0 nsp:@"/swift" ack:true checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeAck);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    XCTAssertEqual(parsed.id, 0);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testBinaryAck {
    NSArray *sendData = @[self.data];
    VPSocketPacket *packet = [VPSocketPacket packetFromEmit:sendData id:0 nsp:@"/swift" ack:true checkForBinary:YES];
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packet.packetString];
    XCTAssertEqual(parsed.type, VPPacketTypeBinaryAck);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    XCTAssertTrue([self compareAnyArray:packet.binary expected:@[self.data]]);
    XCTAssertEqual(parsed.id, 0);
    XCTAssertTrue([self compareAnyArray:packet.binary expected:@[self.data]]);
    NSArray *array = @[@{@"_placeholder":@YES,@"num":@0}];
    XCTAssertTrue([self compareAnyArray:parsed.data expected:array]);
}

- (void)testMultipleBinaryAck {
    NSArray *sendData = @[@{
                              @"data1":self.data,
                              @"data2":self.data2
                              }];
    VPSocketPacket *packet = [VPSocketPacket packetFromEmit:sendData id:0 nsp:@"/swift" ack:true checkForBinary:YES];
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packet.packetString];
    
    XCTAssertEqual(parsed.id, 0);
    XCTAssertEqualObjects(parsed.nsp, @"/swift");
    XCTAssertEqual(parsed.type, VPPacketTypeBinaryAck);
    
    NSDictionary<NSString *, id> *binaryObj = parsed.data[0];
    NSInteger data1Loc = [binaryObj[@"data1"][@"num"] integerValue];
    NSInteger data2Loc = [binaryObj[@"data2"][@"num"] integerValue];
    
    XCTAssertEqual(packet.binary[data1Loc], self.data);
    XCTAssertEqual(packet.binary[data2Loc], self.data2);
}

- (BOOL) compareAnyArray:(NSArray *) input expected:(NSArray *)expected {
    if (input.count != expected.count) {
        return false;
    }
    
    return [input isEqualToArray:expected];
}

@end
