//
//  SchemeHandler.m
//  SchemeHandler
//
//  Created by Ledger Heath on 2024/10/31.
//

#import "SchemeHandler.h"

@interface SchemeHandler() <NSURLSessionDelegate>

@property(nonatomic, strong) NSURLResponse *response;
@property(nonatomic, strong) NSMutableData *data;
@end

@implementation SchemeHandler

- (void)webView:(nonnull WKWebView *)webView startURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask { 
    
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask { 
    
}

@end
