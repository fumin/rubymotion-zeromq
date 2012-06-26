//
//  onlinesession.h
//  onlinesession
//
//  Created by  on 12/6/15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kOnlineSessionErrorDomain @"Online Session Domain"
#define kFailedToSendDataErrorCode 1000
#define kDataReadErrorCode 1001
#define kBufferSize 512

@class OnlineSession;
@protocol OnlineSessionDelegate <NSObject>
- (void)onlineSession:(OnlineSession*)session receivedData:(NSData*)data;
@optional
- (void)onlineSession:(OnlineSession*)session encounteredReadError:(NSError*)error;
- (void)onlineSession:(OnlineSession*)session encounteredWriteError:(NSError*)error;
- (void)onlineSessionDisconnected:(OnlineSession*)session;
@end

@interface OnlineSession : NSObject <NSStreamDelegate>
@property (weak, nonatomic) id<OnlineSessionDelegate> delegate;
- (id) initWithHost:(NSString*)host port:(NSInteger)port;
- (BOOL)sendData:(NSData*)data;
@end
