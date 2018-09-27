//
//  VPSocketBasicPacketTest.m
//  VPIFMSocketIOTests
//
//  Created by yangguang on 2018/7/30.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VPSocketManager.h"
#import "VPSocketPacket.h"

@interface VPSocketBasicPacketTest : XCTestCase
@property (nonatomic, strong) VPSocketManager *parser;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSData *data2;

@end

@implementation VPSocketBasicPacketTest

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
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testEmptyEmit {
    NSArray *sendData = @[@"test"];
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/" ack:false checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeEvent);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testNullEmit {
    NSArray *sendData = @[@"test", [NSNull null]];
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/" ack:false checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeEvent);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testStringEmit {
    NSArray *sendData = @[@"test", @"foo bar"];
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/" ack:false checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeEvent);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testStringEmitWithQuotes {
    NSArray *sendData = @[@"test", @"\"he\"llo world\""];
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/" ack:false checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeEvent);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testJSONEmit {
    NSArray *sendData = @[@"test", @{@"foobar":@YES, @"hello":@1, @"test":@"hello", @"null":[NSNull null]}];
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/" ack:false checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeEvent);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testArrayEmit {
    NSArray *sendData = @[@"test", @[@"hello", @1, @{@"test":@"test"}]];
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/" ack:false checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeEvent);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testBinaryEmit {
    NSArray *sendData = @[@"test", self.data];
    VPSocketPacket *packet = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/" ack:false checkForBinary:YES];
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packet.packetString];
    XCTAssertEqual(parsed.type, VPPacketTypeBinaryEvent);
    XCTAssertTrue([self compareAnyArray:packet.binary expected:@[self.data]]);
    NSArray *array = @[@"test", @{@"_placeholder":@YES,@"num":@0}];
    XCTAssertTrue([self compareAnyArray:parsed.data expected:array]);
}

- (void)testMultipleBinaryEmit {
    NSArray *sendData = @[@"test", @{
                              @"data1":self.data,
                              @"data2":self.data2
                              }];
    VPSocketPacket *packet = [VPSocketPacket packetFromEmit:sendData id:-1 nsp:@"/" ack:false checkForBinary:YES];
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packet.packetString];
    
    XCTAssertEqual(parsed.type, VPPacketTypeBinaryEvent);
    NSDictionary<NSString *, id> *binaryObj = parsed.data[1];
    NSInteger data1Loc = [binaryObj[@"data1"][@"num"] integerValue];
    NSInteger data2Loc = [binaryObj[@"data2"][@"num"] integerValue];
    
    XCTAssertEqual(packet.binary[data1Loc], self.data);
    XCTAssertEqual(packet.binary[data2Loc], self.data2);
}

- (void)testEmitWithAck {
    NSArray *sendData = @[@"test"];
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:0 nsp:@"/" ack:false checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeEvent);
    XCTAssertEqual(parsed.id, 0);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testEmitDataWithAck {
    NSArray *sendData = @[@"test", self.data];
    VPSocketPacket *packet = [VPSocketPacket packetFromEmit:sendData id:0 nsp:@"/" ack:false checkForBinary:YES];
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packet.packetString];
    XCTAssertEqual(parsed.type, VPPacketTypeBinaryEvent);
    XCTAssertEqual(parsed.id, 0);
    NSArray *array = @[@"test", @{@"_placeholder":@YES,@"num":@0}];
    XCTAssertTrue([self compareAnyArray:parsed.data expected:array]);
    XCTAssertTrue([self compareAnyArray:packet.binary expected:@[self.data]]);
}

- (void)testEmptyAck {
    NSString *packetStr = [VPSocketPacket packetFromEmit:@[] id:0 nsp:@"/" ack:true checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeAck);
    XCTAssertEqual(parsed.id, 0);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:@[]]);
}

- (void)testNullAck {
    NSArray *sendData = @[[NSNull null]];
    
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:0 nsp:@"/" ack:true checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeAck);
    XCTAssertEqual(parsed.id, 0);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testStringAck {
    NSArray *sendData = @[@"test"];
    
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:0 nsp:@"/" ack:true checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeAck);
    XCTAssertEqual(parsed.id, 0);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testJSONAck {
    NSArray *sendData = @[@"test", @{@"foobar":@YES, @"hello":@1, @"test":@"hello", @"null":[NSNull null]}];
    
    NSString *packetStr = [VPSocketPacket packetFromEmit:sendData id:0 nsp:@"/" ack:true checkForBinary:YES].packetString;
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packetStr];
    XCTAssertEqual(parsed.type, VPPacketTypeAck);
    XCTAssertEqual(parsed.id, 0);
    XCTAssertTrue([self compareAnyArray:parsed.data expected:sendData]);
}

- (void)testBinaryAck {
    NSArray *sendData = @[self.data];
    VPSocketPacket *packet = [VPSocketPacket packetFromEmit:sendData id:0 nsp:@"/" ack:true checkForBinary:YES];
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packet.packetString];
    XCTAssertEqual(parsed.type, VPPacketTypeBinaryAck);
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
    VPSocketPacket *packet = [VPSocketPacket packetFromEmit:sendData id:0 nsp:@"/" ack:true checkForBinary:YES];
    VPSocketPacket *parsed = [self.parser parseSocketMessage:packet.packetString];
    
    XCTAssertEqual(parsed.id, 0);
    XCTAssertEqual(parsed.type, VPPacketTypeBinaryAck);
    
    NSDictionary<NSString *, id> *binaryObj = parsed.data[0];
    NSInteger data1Loc = [binaryObj[@"data1"][@"num"] integerValue];
    NSInteger data2Loc = [binaryObj[@"data2"][@"num"] integerValue];
    
    XCTAssertEqual(packet.binary[data1Loc], self.data);
    XCTAssertEqual(packet.binary[data2Loc], self.data2);
}

- (void)testBinaryStringPlaceholderInMessage {
    NSString *engineString = @"52-[\"test\",\"~~0\",{\"num\":0,\"_placeholder\":true},{\"_placeholder\":true,\"num\":1}]";
    
    VPSocketManager *manager = [[VPSocketManager alloc] initWithURL:[NSURL URLWithString:@"http://localhost/"] config:nil];
    VPSocketPacket *packet = [manager parseString:engineString];
    XCTAssertTrue([packet.event isEqualToString:@"test"]);
    [packet addData:self.data];
    [packet addData:self.data2];
    NSLog(@"%@",[[NSString alloc]initWithData:packet.args[1] encoding:NSUTF8StringEncoding]);
    XCTAssertTrue([packet.args[0] isEqualToString: @"~~0"]);
}

- (BOOL) compareAnyArray:(NSArray *) input expected:(NSArray *)expected {
    if (input.count != expected.count) {
        return false;
    }
    
    return [input isEqualToArray:expected];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
