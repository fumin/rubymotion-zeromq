//
//  NSStream+QNetworkAdditions.h
//  onlinesession
//
//  Created by  on 12/6/15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSStream (QNetworkAdditions)
+ (void)getStreamsToHostNamed:(NSString *)hostName port:(NSInteger)port inputStream:(out NSInputStream **)inputStreamPtr outputStream:(out NSOutputStream **)outputStreamPtr;

@end
