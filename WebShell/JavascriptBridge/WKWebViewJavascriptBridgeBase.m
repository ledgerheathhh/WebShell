#import "WKWebViewJavascriptBridgeBase.h"
#import "WKWebViewJavascriptBridgeJS.h"

@interface WKWebViewJavascriptBridgeBase ()

@property (nonatomic, strong) NSMutableArray *startupMessageQueue;
@property (nonatomic, strong) NSMutableDictionary *responseCallbacks;
@property (nonatomic, strong) NSMutableDictionary *messageHandlers;
@property (nonatomic, assign) NSInteger uniqueId;

@end

@implementation WKWebViewJavascriptBridgeBase

- (instancetype)init {
    self = [super init];
    if (self) {
        _startupMessageQueue = [NSMutableArray array];
        _responseCallbacks = [NSMutableDictionary dictionary];
        _messageHandlers = [NSMutableDictionary dictionary];
        _uniqueId = 0;
    }
    return self;
}

- (void)reset {
    self.startupMessageQueue = nil;
    self.responseCallbacks = [NSMutableDictionary dictionary];
    self.uniqueId = 0;
}

- (void)sendWithHandlerName:(NSString *)handlerName data:(id)data callback:(WKWebViewJavascriptBridgeCallback)callback {
    NSMutableDictionary *message = [NSMutableDictionary dictionary];
    message[@"handlerName"] = handlerName;
    
    if (data) {
        message[@"data"] = data;
    }
    
    if (callback) {
        self.uniqueId++;
        NSString *callbackID = [NSString stringWithFormat:@"native_iOS_cb_%ld", (long)self.uniqueId];
        self.responseCallbacks[callbackID] = callback;
        message[@"callbackID"] = callbackID;
    }
    
    [self queueMessage:message];
}

- (void)flushMessageQueue:(NSString *)messageQueueString {
    NSArray *messages = [self deserializeMessageJSON:messageQueueString];
    if (!messages) {
        [self log:messageQueueString];
        return;
    }
    
    for (NSDictionary *message in messages) {
        [self log:message];
        
        NSString *responseID = message[@"responseID"];
        if (responseID) {
            WKWebViewJavascriptBridgeCallback callback = self.responseCallbacks[responseID];
            if (callback) {
                callback(message[@"responseData"]);
                [self.responseCallbacks removeObjectForKey:responseID];
            }
            continue;
        }
        
        WKWebViewJavascriptBridgeCallback callback = nil;
        NSString *callbackID = message[@"callbackID"];
        if (callbackID) {
            __weak typeof(self) weakSelf = self;
            callback = ^(id responseData) {
                NSMutableDictionary *msg = [NSMutableDictionary dictionary];
                msg[@"responseID"] = callbackID;
                msg[@"responseData"] = responseData ?: [NSNull null];
                [weakSelf queueMessage:msg];
            };
        } else {
            callback = ^(id responseData) {
                // no logic
            };
        }
        
        NSString *handlerName = message[@"handlerName"];
        if (!handlerName) continue;
        
        WKWebViewJavascriptBridgeHandler handler = self.messageHandlers[handlerName];
        if (!handler) {
            [self log:[NSString stringWithFormat:@"NoHandlerException, No handler for message from JS: %@", message]];
            continue;
        }
        
        handler(message[@"data"], callback);
    }
}

- (void)injectJavascriptFile {
    NSString *js = WKWebViewJavascriptBridgeJS;
    __weak typeof(self) weakSelf = self;
    [self.delegate evaluateJavascript:js completion:^(id result, NSError *error) {
        if (error) {
            [weakSelf log:error];
            return;
        }
        
        for (NSDictionary *message in weakSelf.startupMessageQueue) {
            [weakSelf dispatchMessage:message];
        }
        weakSelf.startupMessageQueue = nil;
    }];
}

- (void)registerHandler:(NSString *)handlerName handler:(WKWebViewJavascriptBridgeHandler)handler {
    self.messageHandlers[handlerName] = handler;
}

- (WKWebViewJavascriptBridgeHandler)removeHandler:(NSString *)handlerName {
    WKWebViewJavascriptBridgeHandler handler = self.messageHandlers[handlerName];
    [self.messageHandlers removeObjectForKey:handlerName];
    return handler;
}

#pragma mark - Private Methods

- (void)queueMessage:(NSDictionary *)message {
    if (self.startupMessageQueue) {
        [self.startupMessageQueue addObject:message];
    } else {
        [self dispatchMessage:message];
    }
}

- (void)dispatchMessage:(NSDictionary *)message {
    NSString *messageJSON = [self serializeMessage:message pretty:NO];
    if (!messageJSON) return;
    
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    
    NSString *javascriptCommand = [NSString stringWithFormat:@"WKWebViewJavascriptBridge._handleMessageFromiOS('%@');", messageJSON];
    
    if ([NSThread isMainThread]) {
        [self.delegate evaluateJavascript:javascriptCommand completion:nil];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate evaluateJavascript:javascriptCommand completion:nil];
        });
    }
}

#pragma mark - JSON Methods

- (NSString *)serializeMessage:(NSDictionary *)message pretty:(BOOL)pretty {
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:message
                                                  options:pretty ? NSJSONWritingPrettyPrinted : 0
                                                    error:&error];
    if (error) {
        [self log:error];
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSArray *)deserializeMessageJSON:(NSString *)messageJSON {
    NSData *data = [messageJSON dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) return nil;
    
    NSError *error;
    NSArray *result = [NSJSONSerialization JSONObjectWithData:data
                                                     options:NSJSONReadingAllowFragments
                                                       error:&error];
    if (error) {
        [self log:error];
        return nil;
    }
    return result;
}

#pragma mark - Log

- (void)log:(id)message {
#if DEBUG
    if (!self.isLogEnable) return;
    
    NSString *fileName = [[NSString stringWithUTF8String:__FILE__] lastPathComponent];
    NSLog(@"%@:%d %s | %@", fileName, __LINE__, __PRETTY_FUNCTION__, message);
#endif
}

@end 