//
//  ViewController.m
//  VPSocketIO
//
//  Created by Vasily Popov on 9/19/17.
//  Copyright © 2017 Vasily Popov. All rights reserved.
//

#import "ViewController.h"
#import <VPSocketIO/VPSocketIO.h>


@interface ClientSocketLogger : VPSocketLogger

@end

@implementation ClientSocketLogger

-(void) log:(NSString*)message type:(NSString*)type
{
    NSLog(@"ClientSocket MESSAGE: %@", message);
}

-(void) error:(NSString*)message type:(NSString*)type
{
    NSLog(@"ClientSocket ERROR %@", message);
}

-(void)dealloc {
    
}

@end


@interface ViewController ()
@property (nonatomic, strong) VPSocketManager *manager;
@property (nonatomic, strong) VPSocketIOClient *socket;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)buttonClicked:(id)sender {
    
    [self socketExample];
    
}
- (IBAction)disconnect:(id)sender {
    
//    [socket removeAllHandlers];
//    [socket disconnect];
//    self->socket = nil;
//    [self.socket disconnect];
    [self.manager disconnectSocket:self.socket];
    
}

-(void)socketExample
{
    ClientSocketLogger*logger = [ClientSocketLogger new];

    NSString *urlString = @"http://localhost:8080";
    NSURL *url = [[NSURL alloc]initWithString:urlString];
    self.manager = [[VPSocketManager alloc]initWithURL:url config:@{@"log":@(NO)}];
//    self.socket = [self.manager defaultSocket];
    self.socket = [self.manager socketFor:@"/web"];
    [self.socket on:@"connect" callback:^(NSArray *array, VPSocketAckEmitter *emitter) {
        NSLog(@"%@",array);
    }];
    [self.socket connect];
    
    
    
    
}
- (IBAction)emit:(id)sender {
    [[self.socket emitWithAck:@"event" items:@[@{}]] timingOutAfter:0 callback:^(NSArray *array) {
        NSLog(@"%@",array);
    }];
}


@end
