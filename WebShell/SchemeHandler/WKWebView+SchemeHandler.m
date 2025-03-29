//
//  WKWebView+SchemeHandler.m
//  SchemeHandler
//
//  Created by Ledger Heath on 2024/10/31.
//

#import "WKWebView+SchemeHandler.h"
#import <objc/runtime.h>

@implementation WKWebView (SchemeHandler)

/**
 * Method swizzling to handle custom URL schemes
 * This is called when the class is loaded
 */
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originMethod = class_getClassMethod(self, @selector(handlesURLScheme:));
        Method customMethod = class_getClassMethod(self, @selector(customHandlesURLScheme:));
        
        if (originMethod && customMethod) {
            method_exchangeImplementations(originMethod, customMethod);
            NSLog(@"Successfully swizzled handlesURLScheme: method");
        } else {
            NSLog(@"Failed to swizzle handlesURLScheme: method");
        }
    });
}

/**
 * Custom implementation of handlesURLScheme:
 * @param urlScheme The URL scheme to check
 * @return NO for custom schemes, otherwise calls original implementation
 */
+ (BOOL)customHandlesURLScheme:(NSString *)urlScheme {
    // Prevent WKWebView from handling our custom scheme
    if ([urlScheme isEqualToString:@"CNMD"]) {
        return NO;
    } else {
        // Call original implementation (now pointing to customHandlesURLScheme: due to swizzling)
        return [self customHandlesURLScheme:urlScheme];
    }
}
@end
