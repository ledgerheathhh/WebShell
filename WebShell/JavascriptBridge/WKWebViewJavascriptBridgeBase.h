#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WKWebViewJavascriptBridgeBaseDelegate <NSObject>
- (void)evaluateJavascript:(NSString *)javascript completion:(nullable void (^)(id _Nullable result, NSError * _Nullable error))completion;
@end

@interface WKWebViewJavascriptBridgeBase : NSObject

@property (nonatomic, assign) BOOL isLogEnable;
@property (nonatomic, weak) id<WKWebViewJavascriptBridgeBaseDelegate> delegate;

typedef void (^WKWebViewJavascriptBridgeCallback)(id _Nullable responseData);
typedef void (^WKWebViewJavascriptBridgeHandler)(NSDictionary * _Nullable parameters, WKWebViewJavascriptBridgeCallback _Nullable callback);

- (void)reset;
- (void)sendWithHandlerName:(NSString *)handlerName data:(nullable id)data callback:(nullable WKWebViewJavascriptBridgeCallback)callback;
- (void)flushMessageQueue:(NSString *)messageQueueString;
- (void)injectJavascriptFile;
- (void)registerHandler:(NSString *)handlerName handler:(WKWebViewJavascriptBridgeHandler)handler;
- (nullable WKWebViewJavascriptBridgeHandler)removeHandler:(NSString *)handlerName;

@end

NS_ASSUME_NONNULL_END 