#import "WKWebViewJavascriptBridge.h"
#import "WKWebViewJavascriptBridgeBase.h"

@interface LeakAvoider : NSObject <WKScriptMessageHandler>

@property (nonatomic, weak) id<WKScriptMessageHandler> delegate;

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate;

@end

@implementation LeakAvoider

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.delegate userContentController:userContentController didReceiveScriptMessage:message];
}

@end

@interface WKWebViewJavascriptBridge () <WKScriptMessageHandler, WKWebViewJavascriptBridgeBaseDelegate>

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, strong) WKWebViewJavascriptBridgeBase *base;
@property (nonatomic, copy) NSString *iOS_Native_InjectJavascript;
@property (nonatomic, copy) NSString *iOS_Native_FlushMessageQueue;

@end

@implementation WKWebViewJavascriptBridge

- (instancetype)initWithWebView:(WKWebView *)webView {
    self = [super init];
    if (self) {
        _webView = webView;
        _base = [[WKWebViewJavascriptBridgeBase alloc] init];
        _base.delegate = self;
        _iOS_Native_InjectJavascript = @"iOS_Native_InjectJavascript";
        _iOS_Native_FlushMessageQueue = @"iOS_Native_FlushMessageQueue";
        [self addScriptMessageHandlers];
    }
    return self;
}

- (void)dealloc {
    [self removeScriptMessageHandlers];
}

- (void)setIsLogEnable:(BOOL)isLogEnable {
    self.base.isLogEnable = isLogEnable;
}

- (BOOL)isLogEnable {
    return self.base.isLogEnable;
}

#pragma mark - Public Methods

- (void)reset {
    [self.base reset];
}

- (void)registerHandler:(NSString *)handlerName handler:(void (^)(NSDictionary * _Nullable, void (^ _Nullable)(id _Nullable)))handler {
    [self.base registerHandler:handlerName handler:handler];
}

- (void (^)(NSDictionary * _Nullable, void (^ _Nullable)(id _Nullable)))removeHandler:(NSString *)handlerName {
    return [self.base removeHandler:handlerName];
}

- (void)callHandler:(NSString *)handlerName data:(id)data callback:(void (^)(id _Nullable))callback {
    [self.base sendWithHandlerName:handlerName data:data callback:callback];
}

#pragma mark - Private Methods

- (void)flushMessageQueue {
    [self.webView evaluateJavaScript:@"WKWebViewJavascriptBridge._fetchQueue();" completionHandler:^(id result, NSError *error) {
        if (error) {
            NSLog(@"WKWebViewJavascriptBridge: WARNING: Error when trying to fetch data from WKWebView: %@", error);
            return;
        }
        
        if ([result isKindOfClass:[NSString class]]) {
            [self.base flushMessageQueue:result];
        }
    }];
}

- (void)addScriptMessageHandlers {
    [self.webView.configuration.userContentController addScriptMessageHandler:[[LeakAvoider alloc] initWithDelegate:self] name:self.iOS_Native_InjectJavascript];
    [self.webView.configuration.userContentController addScriptMessageHandler:[[LeakAvoider alloc] initWithDelegate:self] name:self.iOS_Native_FlushMessageQueue];
}

- (void)removeScriptMessageHandlers {
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:self.iOS_Native_InjectJavascript];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:self.iOS_Native_FlushMessageQueue];
}

#pragma mark - WKWebViewJavascriptBridgeBaseDelegate

- (void)evaluateJavascript:(NSString *)javascript completion:(void (^)(id _Nullable, NSError * _Nullable))completion {
    [self.webView evaluateJavaScript:javascript completionHandler:completion];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:self.iOS_Native_InjectJavascript]) {
        [self.base injectJavascriptFile];
    }
    
    if ([message.name isEqualToString:self.iOS_Native_FlushMessageQueue]) {
        [self flushMessageQueue];
    }
}

@end
