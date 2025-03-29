//
//  ViewController.m
//  WebShell
//
//  Created by Ledger Heath on 2024/10/15.
//

#import "ViewController.h"
#import "WebKit/WebKit.h"
#import "SchemeHandler.h"

// Constants
NSString * const kCustomURLScheme = @"QuantumLink";

@interface ViewController () <WKNavigationDelegate>

@property(nonatomic, strong) NSString *url;
@property(nonatomic, strong) UIProgressView *progressView;
@property(nonatomic, strong) WKWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.webView addSubview:self.progressView];
    [self addObserve];
    
    // 1. Loading online webpage via http/https
//    NSURL *url = [NSURL URLWithString:@"https://www.apple.com"];
//    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    [webView loadRequest:request];
    
    // 2. Loading local files via File protocol
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
//    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
//    // Directory allowed for access
//    NSURL *readAccessURL = [fileURL URLByDeletingLastPathComponent];
//    // Load local HTML file
//    [webView loadFileURL:fileURL allowingReadAccessToURL:readAccessURL];

    // 3. Loading webpage via custom protocol
    NSString *urlString = [NSString stringWithFormat:@"%@://www.ledgerheath.com/index.html", kCustomURLScheme];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

// Called when page starts loading
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"Page loading started");
}

// Called when page finishes loading
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"Page loading completed");
}

// Called when page loading fails
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"Page loading failed: %@", error.localizedDescription);
}

#pragma mark - Add Observers
- (void)addObserve{
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserve{
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == self.webView) {
        if ([keyPath isEqualToString:@"estimatedProgress"]) {// Progress bar
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
            [wkWebConfig setURLSchemeHandler:SchemeHandler.new forURLScheme:kCustomURLScheme];
        }

        // Create WKWebView
        WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:wkWebConfig];
        webView.navigationDelegate = self;
        [self.view addSubview:webView];
        
        // Disable automatically generated constraints
        webView.translatesAutoresizingMaskIntoConstraints = NO;

        // Set constraints to use the entire screen
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

// Progress bar
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
    
    // Stop HTML5 audio playback
    if (_webView) {
        [_webView evaluateJavaScript:@"" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
            
        }];
    }
}
@end
