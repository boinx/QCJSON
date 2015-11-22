/*
 Copyright (c) 2013 Boinx Software Ltd.
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Quartz/Quartz.h>


@interface QCJSONPlugIn : QCPlugIn
{
	NSThread *_connectionThread;
	NSTimer *_connectionThreadTimer;
	NSURLConnection *_connection;
	NSMutableData *_content;
	long long _contentLength;

	NSString *_JSONLocation;
	NSDictionary *_HTTPHeaders;
	NSString *_bodyString;

	NSDictionary *_parsedJSON;
	double _downloadProgress;
	NSNumber *_doneSignal;
	NSError *_error;	
}

@property (assign) NSString *inputJSONLocation;
@property (assign) NSDictionary *inputHTTPHeaders;
@property (assign) NSString *inputBodyString;
@property (assign) BOOL inputUpdateSignal;

@property (assign) NSDictionary *outputParsedJSON;
@property (assign) double outputDownloadProgress;
@property (assign) BOOL outputDoneSignal;

@end
