#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebViewJavascriptBridge : NSObject

@property (nonatomic, assign) BOOL isLogEnable;

- (instancetype)initWithWebView:(WKWebView *)webView;
- (void)reset;
- (void)registerHandler:(NSString *)handlerName handler:(void (^)(NSDictionary * _Nullable parameters, void (^ _Nullable callback)(id _Nullable responseData)))handler;
- (void (^)(NSDictionary * _Nullable parameters, void (^ _Nullable callback)(id _Nullable responseData)))removeHandler:(NSString *)handlerName;
- (void)callHandler:(NSString *)handlerName data:(nullable id)data callback:(nullable void (^)(id _Nullable responseData))callback;

@end

NS_ASSUME_NONNULL_END 