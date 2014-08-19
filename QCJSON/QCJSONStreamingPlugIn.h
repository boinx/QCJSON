/*
 Copyright (c) 2013 Boinx Software Ltd.
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Quartz/Quartz.h>


@interface QCJSONStreamingPlugIn : QCPlugIn
{
	NSThread *_connectionThread;
	NSTimer *_connectionThreadTimer;
	NSURLConnection *_connection;
	NSMutableString *_jsonMessage;
	NSInteger _jsonLength;

	NSDictionary *_parsedJSON;
	NSNumber *_statusCode;
	NSNumber *_doneSignal;
	NSNumber *_connecting;
	NSNumber *_connected;
	NSError *_error;
	BOOL _replaceXMLEntities;
}

@property (assign) NSString *inputJSONLocation;
@property (assign) NSString *inputHTTPMethod;
@property (assign) NSDictionary *inputHTTPHeaders;
@property (assign) BOOL inputUpdateSignal;
@property (assign) BOOL inputReplaceXMLEntities;

@property (assign) NSDictionary *outputParsedJSON;
@property (assign) NSUInteger outputStatusCode;
@property (assign) BOOL outputDoneSignal;
@property (assign) BOOL outputConnecting;
@property (assign) BOOL outputConnected;

@end
