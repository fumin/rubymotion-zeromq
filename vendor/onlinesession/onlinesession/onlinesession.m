//
//  onlinesession.m
//  onlinesession
//
//  Created by  on 12/6/15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "onlinesession.h"
#import "NSStream+QNetworkAdditions.h"

@interface OnlineSession () 
@property (strong, nonatomic) NSInputStream* _inStream;
@property (strong, nonatomic) NSOutputStream* _outStream;
@property (strong, nonatomic) NSMutableData* _readBuf;
@property (strong, nonatomic) NSMutableData* _writeBuf;
@property BOOL _can_write;

-(void)sendQueuedData;
@end

@implementation OnlineSession

@synthesize delegate;
@synthesize _inStream;
@synthesize _outStream;
@synthesize _readBuf;
@synthesize _writeBuf;
@synthesize _can_write;
-(id)initWithHost:(NSString*)host port:(NSInteger)port{
    if (self = [super init]) {
        NSInputStream* is;
        NSOutputStream* os;
        [NSStream getStreamsToHostNamed:host port:port inputStream:&is outputStream:&os];
        self._inStream = is;
        self._outStream = os;
        [self._inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self._outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self._inStream.delegate = self;
        self._outStream.delegate = self;
        [self._inStream open];
        [self._outStream open];
        self._readBuf = [[NSMutableData alloc] init];
        self._writeBuf = [[NSMutableData alloc] init];
        self._can_write = FALSE;
        return self;
    } else {
        return nil;
    }
}
-(void)dealloc{
    [self._inStream close];
    [self._inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self._inStream.delegate = nil;
    [self._outStream close];
    [self._outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self._outStream.delegate = nil;
}
-(BOOL)sendData:(NSData*)data{
    if (data == nil || [data length] == 0) return NO;
    [self._writeBuf appendBytes:"\x00" length:1];
    [self._writeBuf appendData:data];
    [self._writeBuf appendBytes:"\xff" length:1];
    if (self._can_write) {
        [self sendQueuedData];
        self._can_write = FALSE;
    }
    return YES;
}
-(void)sendQueuedData{
    uint8_t* readBytes = [self._writeBuf mutableBytes];
    int data_len = [self._writeBuf length];
    unsigned int len = data_len > kBufferSize ? kBufferSize : data_len;
    len = [self._outStream write:readBytes maxLength:len];
    if (len <= 0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(onlineSession:encounteredWriteError:)]) {
            [self.delegate onlineSession:self encounteredWriteError:[self._outStream streamError]];
        }
        return;
    }
    [self._writeBuf replaceBytesInRange:NSMakeRange(0, len) withBytes:NULL length:0];
}
-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable:{
            if (aStream == self._outStream) {
                if (self._writeBuf == nil || [self._writeBuf length] == 0) {
                    self._can_write = TRUE;
                } else {
                    [self sendQueuedData];
                }
            }
            break;
        }
        case NSStreamEventHasBytesAvailable:{
            if (aStream == self._inStream) {
                uint8_t buf[kBufferSize];
                unsigned int len = 0;
                len = [self._inStream read:buf maxLength:kBufferSize];
                if (len <= 0 && [self.delegate respondsToSelector:@selector
                                 (onlineSession:encounteredReadError:)]) {
                    NSError *error = [[NSError alloc]
                                      initWithDomain:kOnlineSessionErrorDomain
                                      code:kDataReadErrorCode userInfo:nil];
                    [self.delegate onlineSession:self encounteredReadError:error];
                    return;
                } else {
                    [self._readBuf appendBytes:buf length:len];
                    uint8_t* p_start = (uint8_t*)[self._readBuf bytes];
                    uint8_t* p_end = p_start + [self._readBuf length];
                    uint8_t* p1 = p_start;
                    uint8_t* p2 = p1;
                    while (p2 != p_end) {
                        if (*p2 == 0xff) {
                            [self.delegate onlineSession:self receivedData:[NSData dataWithBytesNoCopy:p1+1 length:(p2-p1-1) freeWhenDone:FALSE]];
                            p1 = p2 + 1;
                            p2 = p1;
                        } else {
                            ++p2;
                        }
                    }
                    [self._readBuf replaceBytesInRange:NSMakeRange(0, p1-p_start) withBytes:NULL length:0];
                }
            }
            break;
        }
        case NSStreamEventErrorOccurred: {
            NSError *theError = [aStream streamError];
            if (aStream == self._inStream)
                if (self.delegate && [self.delegate respondsToSelector:@selector(onlineSession:encounteredReadError:)])
                    [self.delegate onlineSession:self encounteredReadError:theError];
                else{
                    if (self.delegate && [self.delegate respondsToSelector:@selector(onlineSession:encounteredWriteError:)])
                        [self.delegate onlineSession:self encounteredWriteError:theError];}
            break; 
        }
        case NSStreamEventEndEncountered:
            if (self.delegate && [self.delegate respondsToSelector:
                                  @selector(onlineSessionDisconnected:)])
                [self.delegate onlineSessionDisconnected:self];
            break;
        default:
            break;
    }
}

@end
