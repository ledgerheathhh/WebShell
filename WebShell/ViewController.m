//
//  ViewController.m
//  WebShell
//
//  Created by Ledger Heath on 2024/10/15.
//

#import "ViewController.h"
#import "WebKit/WebKit.h"
#import "SchemeHandler.h"

@interface ViewController () <WKNavigationDelegate>

@property(nonatomic, strong)NSString *url;

@property(nonatomic, strong)UIProgressView *progressView;

@property(nonatomic, strong)WKWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.webView addSubview:self.progressView];
    [self addObserve];
    
    // 1、http/https加载在线网页
//    NSURL *url = [NSURL URLWithString:@"https://www.apple.com"];
//    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    [webView loadRequest:request];
    
    // 2、File协议加载本地
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
//    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
//    // 允许访问的目录
//    NSURL *readAccessURL = [fileURL URLByDeletingLastPathComponent];
//    // 加载本地 HTML 文件
//    [webView loadFileURL:fileURL allowingReadAccessToURL:readAccessURL];

    // 3、自定义协议加载网页
    NSURL *url = [NSURL URLWithString:@"CNMD://www.ledgerheath.com/index.html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"页面开始加载");
}

// 页面加载完成时调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"页面加载完成");
}

// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"页面加载失败: %@", error.localizedDescription);
}

#pragma mark - 添加观察
- (void)addObserve{
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserve{
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == self.webView) {
        if ([keyPath isEqualToString:@"estimatedProgress"]) {//进度条
            [self.progressView setAlpha:1.0f];
            [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
            
            if(self.webView.estimatedProgress >= 1.0f) {
                
                [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    [self.progressView setAlpha:0.0f];
                } completion:^(BOOL finished) {
                    [self.progressView setProgress:0.0f animated:NO];
                }];
            }
        }
    }
}

- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *wkWebConfig = [[WKWebViewConfiguration alloc] init];
        if (@available(iOS 11.0, *)) {
            [wkWebConfig setURLSchemeHandler:SchemeHandler.new forURLScheme:@"CNMD"];
        }

        // 创建 WKWebView
        WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:wkWebConfig];
        webView.navigationDelegate = self;
        [self.view addSubview:webView];
        
        // 禁用自动生成的约束
        webView.translatesAutoresizingMaskIntoConstraints = NO;

        // 设置约束，使用整个屏幕
        [NSLayoutConstraint activateConstraints:@[
            [webView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
            [webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
            [webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
            [webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
        ]];
        _webView = webView;
    }
    return _webView;
}

// 进度条
- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 44, self.view.frame.size.width, 0)];
        _progressView.tintColor = [UIColor blueColor];
        _progressView.trackTintColor = [UIColor whiteColor];
    }
    _progressView.center = self.view.center;
    return _progressView;
}

- (void)dealloc{
    [self removeObserve];
    _webView.UIDelegate = nil;
    _webView.navigationDelegate = nil;
    _webView.scrollView.delegate = nil;
    
    //H5停止音频播放
    if (_webView) {
        [_webView evaluateJavaScript:@"" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
            
        }];
    }
}
@end
