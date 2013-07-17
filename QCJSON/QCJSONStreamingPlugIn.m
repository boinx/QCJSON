/*
 Copyright (c) 2013 Boinx Software Ltd.
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "QCJSONStreamingPlugIn.h"

#ifndef NSAppKitVersionNumber10_7
#define NSAppKitVersionNumber10_7 1138
#endif


static NSString * QCJSONStreamingPlugInInputJSONLocation = @"inputJSONLocation";
static NSString * QCJSONStreamingPlugInInputUpdateSignal = @"inputUpdateSignal";


@interface QCJSONStreamingPlugIn () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

+ (NSBundle *)bundle;

@property (strong) NSThread *connectionThread;

// only the connectionThread must access this properties
@property (nonatomic, strong) NSTimer *connectionThreadTimer;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableString *jsonMessage;
@property (nonatomic, assign) NSInteger jsonLength;

@property (strong) NSDictionary *parsedJSON;
@property (strong) NSNumber *doneSignal;
@property (strong) NSNumber *connectedSignal;
@property (strong) NSError *error;

@end




@implementation QCJSONStreamingPlugIn

@dynamic inputJSONLocation;
@dynamic inputHTTPHeaders;
@dynamic inputUpdateSignal;

@dynamic outputParsedJSON;
@dynamic outputDoneSignal;
@dynamic outputConnectedSignal;

@synthesize connectionThread = _connectionThread;
@synthesize connectionThreadTimer = _connectionThreadTimer;
@synthesize connection = _connection;
@synthesize jsonMessage = _jsonMessage;
@synthesize jsonLength = _jsonLength;

@synthesize parsedJSON = _parsedJSON;
@synthesize doneSignal = _doneSignal;
@synthesize connectedSignal = _connectedSignal;
@synthesize error = _error;

+ (NSBundle *)bundle
{
	return [NSBundle bundleForClass:self];
}

+ (NSDictionary *)attributes
{
	NSBundle *bundle = [self bundle];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    
	[attributes setObject:@"JSON Stream" forKey:QCPlugInAttributeNameKey];
	[attributes setObject:@"JSON Stream" forKey:QCPlugInAttributeDescriptionKey];
	[attributes setObject:NSLocalizedStringWithDefaultValue(@"PlugInCopyright", nil, bundle, @"© 2013 Boinx Software Ltd.", @"Copyright text") forKey:QCPlugInAttributeCopyrightKey];
    
#if 0
#if defined(MAC_OS_X_VERSION_10_7) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_7)
	if(&QCPlugInAttributeCategoriesKey)
    {
		NSArray *categories = [NSLocalizedStringWithDefaultValue(@"PlugInCategories", nil, bundle, @"Program;Utility", @"Categories seperated by semicolon") componentsSeparatedByString:@";"];
		if(categories.count > 0)
		{
			[attributes setObject:categories forKey:QCPlugInAttributeCategoriesKey];
		}
	}
#endif
    
#if defined(MAC_OS_X_VERSION_10_7) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_7)
    if(&QCPlugInAttributeExamplesKey)
    {
		NSArray *exampleStrings = [NSLocalizedStringWithDefaultValue(@"PlugInExamples", nil, bundle, @"http://www.boinx.com;http://www.lua.org", @"Example URLs seperated by semicolon") componentsSeparatedByString:@";"];
		NSMutableArray *examples = [NSMutableArray arrayWithCapacity:exampleStrings.count];
		for(NSString *exampleString in exampleStrings)
		{
			[examples addObject:[NSURL URLWithString:exampleString]];
		}

		if(examples.count > 0)
		{
			[attributes setObject:examples forKey:QCPlugInAttributeExamplesKey];
  
		}
	}
#endif
#endif

	return attributes;
}

+ (NSDictionary *)attributesForPropertyPortWithKey:(NSString *)key
{
	if([key isEqualToString:QCJSONStreamingPlugInInputJSONLocation])
	{
		return @{ QCPortAttributeNameKey: @"JSON Location" };
	}
	
	if([key isEqualToString:@"inputHTTPHeaders"])
	{
		return @{ QCPortAttributeNameKey: @"HTTP Headers" };
	}
	
	if([key isEqualToString:QCJSONStreamingPlugInInputUpdateSignal])
	{
		return @{ QCPortAttributeNameKey: @"Update Signal" };
	}
		
	if([key isEqualToString:@"outputParsedJSON"])
	{
		return @{ QCPortAttributeNameKey: @"Parsed JSON" };
	}

	if([key isEqualToString:@"outputDoneSignal"])
	{
		return @{ QCPortAttributeNameKey: @"Done Signal" };
	}

	return nil;
}

+ (NSArray *)plugInKeys
{
	return nil;
}

+ (QCPlugInExecutionMode)executionMode
{
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode)timeMode
{
	return kQCPlugInTimeModeIdle;
}

- (id)init
{
	self = [super init];
	if(self != nil)
	{
		NSThread *connectionThread = [[NSThread alloc] initWithTarget:self selector:@selector(startConnectionThread) object:nil];
		self.connectionThread = connectionThread;
		
		connectionThread.name = @"QCJSON.ConnectionThead";
		[connectionThread start];
	}
	return self;
}

- (void)dealloc
{
	NSThread *connectionThread = self.connectionThread;
	if(connectionThread != nil)
	{
		[self performSelector:@selector(stopConnectionThread) onThread:connectionThread withObject:nil waitUntilDone:YES];
		self.connectionThread = nil;
	}
	
	[self.connection cancel];
	
	self.connection = nil;
	self.jsonMessage = nil;

	self.parsedJSON = nil;
	self.doneSignal = nil;
	self.connectedSignal = nil;
	self.error = nil;
	
	[super dealloc];
}

- (void)startConnectionThread
{
	@autoreleasepool
	{
		NSTimeInterval timeInterval = [NSDate.distantFuture timeIntervalSinceNow];
		self.connectionThreadTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(connectionTimerFired) userInfo:nil repeats:NO];

		CFRunLoopRun();
	}
}

- (void)stopConnectionThread
{
	[self stopConnection];
	
	if(self.connectionThreadTimer != nil)
	{
		[self.connectionThreadTimer invalidate];
		self.connectionThreadTimer = nil;
	}
	
	CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connectionTimerFired
{
	
}

- (void)startConnection
{
	@autoreleasepool
	{
		[self stopConnection];
	
		NSString *JSONLocation = self.inputJSONLocation;
		if(JSONLocation == nil)
		{
			return;
		}
	
		NSURL *URL = [NSURL URLWithString:JSONLocation];
	
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
		
		NSDictionary *HTTPHeaders = self.inputHTTPHeaders;
		for(NSString *key in HTTPHeaders)
		{
			NSString *value = [HTTPHeaders objectForKey:key];
		
			[request setValue:value forHTTPHeaderField:key];
		}
	
		self.jsonMessage = nil;

		self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	
		self.doneSignal = @NO;
		self.connectedSignal = @YES;
	}
}

- (void)stopConnection
{
	@autoreleasepool
	{
		[self.connection cancel];
		self.connection = nil;
	}
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self stopConnection];
	
	self.doneSignal = @NO;
	self.connectedSignal = @NO;
	
	self.error = error;
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if(![response isKindOfClass:NSHTTPURLResponse.class])
	{
		[self stopConnection];
		
		self.doneSignal = @NO;
		self.connectedSignal = @NO;
		
		return;
	}
	
	NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
	
	NSInteger statusCode = HTTPResponse.statusCode;
	if(statusCode != 200)
	{
		[self stopConnection];
			
		self.doneSignal = @NO;
		self.connectedSignal = @NO;
		
		NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: [NSHTTPURLResponse localizedStringForStatusCode:statusCode] };
		self.error = [NSError errorWithDomain:NSURLErrorDomain code:statusCode userInfo:userInfo];
			
		return;
	}
	
	self.jsonLength = 0;
	self.jsonMessage = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	@autoreleasepool {
		NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		
		NSString *delimiter = @"\r\n";
		
		NSInteger length = self.jsonLength;
		NSMutableString *message = self.jsonMessage;
		
		NSArray *components = [string componentsSeparatedByString:delimiter];
		for(NSString *component in components)
		{
			if(length == 0)
			{
				length = [component integerValue];
				message = [NSMutableString stringWithCapacity:length];
			}
			else if(message.length < length)
			{
				[message appendString:component];
				
				if(message.length < length)
				{
					[message appendString:delimiter];
				}
				
				if(message.length == length)
				{
					NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
					
					NSError *error = nil;
					NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
										
					if(JSON != nil)
					{
						self.parsedJSON = JSON;
						self.doneSignal = @YES;
					}
					else
					{
						self.error = error;
					}
					
					length = 0;
					message = nil;
				}
			}
		}
		
		self.jsonLength = length;
		self.jsonMessage = message;
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	self.connectedSignal = @NO;

	[self stopConnection];
}

@end


@implementation QCJSONStreamingPlugIn (Execution)

- (BOOL)startExecution:(id<QCPlugInContext>)context
{
	return YES;
}

- (void)enableExecution:(id <QCPlugInContext>)context
{
}

- (BOOL)execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary *)arguments
{
	if([self didValueForInputKeyChange:QCJSONStreamingPlugInInputUpdateSignal] && self.inputUpdateSignal == YES)
	{
		[self performSelector:@selector(startConnection) onThread:self.connectionThread withObject:nil waitUntilDone:YES];
	}
	
	if(self.doneSignal != nil)
	{
		if(self.doneSignal.boolValue)
		{
			self.outputParsedJSON = self.parsedJSON;
			self.outputDoneSignal = YES;
			
			self.parsedJSON = nil;
			
			self.doneSignal = @NO;
		}
		else
		{
			self.outputDoneSignal = NO;
			
			self.doneSignal = nil;
		}
	}
	
	if(self.connectedSignal != nil)
	{
		self.outputConnectedSignal = self.connectedSignal.boolValue;
		self.connectedSignal = nil;
	}
	
	if(self.error)
	{
		[context logMessage:@"JSON Import error: %@", self.error];
		
		self.error = nil;
	}
	
	return YES;
}

- (void)disableExecution:(id <QCPlugInContext>)context
{
}

- (void)stopExecution:(id <QCPlugInContext>)context
{
}

@end
