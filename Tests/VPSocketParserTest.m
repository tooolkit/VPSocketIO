//
//  VPSocketParserTest.m
//  VPIFMSocketIOTests
//
//  Created by yangguang on 2018/7/30.
//  Copyright © 2018年 tooolkit. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VPSocketManager.h"
#import "tuples.h"
#import "VPSocketPacket.h"
#import "VPStringReader.h"

@interface VPSocketParserTest : XCTestCase

@property (nonatomic, strong) VPSocketManager *testManager;

@end

@implementation VPSocketParserTest

- (void)setUp {
    [super setUp];
    self.testManager = [[VPSocketManager alloc] initWithURL:[NSURL URLWithString:@"http://localhost/"] config:nil];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testDisconnect {
    NSString *message = @"1";
    [self validateParseResult:message];
}

- (void)testConnect {
    NSString *message = @"0";
    [self validateParseResult:message];
}

- (void)testDisconnectNameSpace {
    NSString *message = @"1/swift";
    [self validateParseResult:message];
}

- (void)testConnecttNameSpace {
    NSString *message = @"0/swift";
    [self validateParseResult:message];
}

- (void)testIdEvent {
    NSString *message = @"25[\"test\"]";
    [self validateParseResult:message];
}

- (void)testBinaryPlaceholderAsString {
    NSString *message = @"2[\"test\",\"~~0\"]";
    [self validateParseResult:message];
}

- (void)testNameSpaceArrayParse {
    NSString *message = @"2/swift,[\"testArrayEmitReturn\",[\"test3\",\"test4\"]]";
    [self validateParseResult:message];
}

- (void)testNameSpaceArrayAckParse {
    NSString *message = @"3/swift,0[[\"test3\",\"test4\"]]";
    [self validateParseResult:message];
}

- (void)testNameSpaceBinaryEventParse {
    NSString *message = @"51-/swift,[\"testMultipleItemsWithBufferEmitReturn\",[1,2],{\"test\":\"bob\"},25,\"polo\",{\"_placeholder\":true,\"num\":0}]";
    [self validateParseResult:message];
}

- (void)testNameSpaceBinaryAckParse {
    NSString *message = @"61-/swift,19[[1,2],{\"test\":\"bob\"},25,\"polo\",{\"_placeholder\":true,\"num\":0}]";
    [self validateParseResult:message];
}

- (void)testNamespaceErrorParse {
    NSString *message = @"4/swift,";
    [self validateParseResult:message];
}

- (void)testErrorTypeString {
    NSString *message = @"4\"ERROR\"";
    [self validateParseResult:message];
}

- (void)testErrorTypeDictionary {
    NSString *message = @"4{\"test\":2}";
    [self validateParseResult:message];
}

- (void)testErrorTypeInt {
    NSString *message = @"41";
    [self validateParseResult:message];
}

- (void)testErrorTypeArray {
    NSString *message = @"4[1, \"hello\"]";
    [self validateParseResult:message];
}

- (void)testInvalidInput {
    NSString *message = @"8";
    VPSocketPacket *packet = [self.testManager parseString:message];
    if (packet) {
        XCTFail();
    }
}

- (void)testGenericParser {
    
    VPStringReader *parser = [[VPStringReader alloc]init:@"61-/swift,"];
    XCTAssertEqualObjects([parser read:1], @"6");
    XCTAssertEqualObjects(parser.currentCharacter, @"1");
    XCTAssertEqualObjects([parser readUntilOccurence:@"-"], @"1");
    XCTAssertEqualObjects(parser.currentCharacter, @"/");
}

- (void)validateParseResult:(NSString *)message {
    Tuple* tup = [self packetTypes][message];
    VPSocketPacket *packet = [self.testManager parseString:message];
    NSString *type = [message substringToIndex:1];
    
    XCTAssertEqual(packet.type, [self typeBy:[type intValue]]);
    XCTAssertEqualObjects(packet.nsp, tup[0]);
    XCTAssertTrue([packet.data isEqualToArray:tup[1]]);
    XCTAssertTrue([packet.binary isEqualToArray:tup[2]]);
    XCTAssertEqual(packet.id, [tup[3] intValue]);
}

- (VPPacketType)typeBy:(NSInteger)type {
    switch (type) {
        case 0:
            return VPPacketTypeConnect;
        case 1:
            return VPPacketTypeDisconnect;
        case 2:
            return VPPacketTypeEvent;
        case 3:
            return VPPacketTypeAck;
        case 4:
            return VPPacketTypeError;
        case 5:
            return VPPacketTypeBinaryEvent;
        case 6:
            return VPPacketTypeBinaryAck;
        default:
            return -1;
    }
}

- (NSDictionary *)packetTypes {
    return @{
             @"0":tuple(@"/", @[], @[], @(-1)),
             @"1":tuple(@"/", @[], @[], @(-1)),
             @"25[\"test\"]": tuple(@"/", @[@"test"], @[], @(5)),
             @"2[\"test\",\"~~0\"]": tuple(@"/", @[@"test", @"~~0"], @[], @(-1)),
             @"2/swift,[\"testArrayEmitReturn\",[\"test3\",\"test4\"]]": tuple(@"/swift", @[@"testArrayEmitReturn", @[@"test3", @"test4"]], @[], @(-1)),
                                                        @"51-/swift,[\"testMultipleItemsWithBufferEmitReturn\",[1,2],{\"test\":\"bob\"},25,\"polo\",{\"_placeholder\":true,\"num\":0}]": tuple(@"/swift", @[@"testMultipleItemsWithBufferEmitReturn", @[@1, @2], @{@"test": @"bob"}, @25, @"polo", @{@"_placeholder": @YES, @"num": @0}], @[], @(-1)),
             
                                                                                                                                                                                                            @"61-/swift,19[[1,2],{\"test\":\"bob\"},25,\"polo\",{\"_placeholder\":true,\"num\":0}]":
                                                                                                                                                                                                            tuple(@"/swift", @[ @[@1, @2], @{@"test": @"bob"}, @25, @"polo", @{@"_placeholder": @YES, @"num": @0}], @[], @19),
             
                                                                                                                                                                                                                               @"4/swift,": tuple(@"/swift", @[], @[], @(-1)),
                                                        @"0/swift" : tuple(@"/swift", @[], @[], @(-1)),
                                                        @"1/swift": tuple(@"/swift", @[], @[], @(-1)),
                                                        @"4\"ERROR\"": tuple(@"/", @[@"ERROR"], @[], @(-1)),
                                                                                                                                                                                                                               @"4{\"test\":2}": tuple(@"/", @[@{@"test": @2}], @[], @(-1)),
                                                        @"41": tuple(@"/", @[@1], @[], @(-1)),
                                                        @"4[1, \"hello\"]": tuple(@"/", @[@1, @"hello"], @[], @(-1)),
             @"3/swift,0[[\"test3\",\"test4\"]]": tuple(@"/swift", @[@[@"test3", @"test4"]], @[], @0),
             };
}



@end
