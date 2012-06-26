//
//  NSStream+QNetworkAdditions.m
//  onlinesession
//
//  Created by  on 12/6/15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "NSStream+QNetworkAdditions.h"

@implementation NSStream (QNetworkAdditions)
+ (void)getStreamsToHostNamed:(NSString *)hostName port:(NSInteger)port inputStream:(out NSInputStream **)inputStreamPtr outputStream:(out NSOutputStream **)outputStreamPtr
{
    CFReadStreamRef     readStream;
    CFWriteStreamRef    writeStream;
    
    assert(hostName != nil);
    assert( (port > 0) && (port < 65536) );
    assert( (inputStreamPtr != NULL) || (outputStreamPtr != NULL) );
    
    readStream = NULL;
    writeStream = NULL;
    
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef) hostName, port, ((inputStreamPtr  != NULL) ? &readStream : NULL), ((outputStreamPtr != NULL) ? &writeStream : NULL));
    
    if (inputStreamPtr != NULL) {
        *inputStreamPtr  = CFBridgingRelease(readStream);
    }
    if (outputStreamPtr != NULL) {
        *outputStreamPtr = CFBridgingRelease(writeStream);
    }
}

@end
