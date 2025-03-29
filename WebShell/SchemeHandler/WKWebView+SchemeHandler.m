//
//  WKWebView+SchemeHandler.m
//  SchemeHandler
//
//  Created by Ledger Heath on 2024/10/31.
//

#import "WKWebView+SchemeHandler.h"
#import <objc/runtime.h>

@implementation WKWebView (SchemeHandler)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originMethod = class_getClassMethod(self, @selector(handlesURLScheme:));
        Method customMethod = class_getClassMethod(self, @selector(customHandlesURLScheme:));
    });
}

+ (BOOL)customHandlesURLScheme:(NSString *)urlScheme {
    if([urlScheme isEqualToString:@"CNMD"]){
        return NO;
    }else {
        return [self handlesURLScheme:urlScheme];
    }
}
@end
