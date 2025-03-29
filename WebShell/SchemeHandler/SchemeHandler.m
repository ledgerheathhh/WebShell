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

/**
 * Handles the start of a URL scheme task
 * @param webView The WKWebView that initiated the task
 * @param urlSchemeTask The task to be handled
 */
- (void)webView:(nonnull WKWebView *)webView startURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask {
    
    if (!urlSchemeTask || !urlSchemeTask.request) {
        NSLog(@"Error: Invalid URL scheme task or request");
        return;
    }
    
    NSURLRequest *request = urlSchemeTask.request;
    NSString *urlString = request.URL.absoluteString;
    NSDictionary *headerField = request.allHTTPHeaderFields;
    NSMutableDictionary *headerFields = [[NSMutableDictionary alloc] initWithDictionary:headerField];
    
    // Set CORS headers if not already present
    if (![headerFields objectForKey:@"Access-Control-Allow-Origin"]) {
        [headerFields setObject:@"*" forKey:@"Access-Control-Allow-Origin"];
    }
    
    // Determine file type and handle resource loading
    NSString *mimeType = [self mimeTypeForPath:urlString];
    BOOL isSupported = [self isSupportedFileType:urlString];
    
    if (!isSupported) {
        [self handleUnsupportedFileType:urlSchemeTask withRequest:request];
        return;
    }
    
    // Load resource from cache
    [self getCacheDataByURL:urlString AndCompletion:^(NSData *result) {
        if (!result) {
            [self handleResourceNotFound:urlSchemeTask withRequest:request urlString:urlString];
            return;
        }
        
        // Create response with appropriate headers
        NSData *responseData = result;
        NSDictionary *responseHeaders = @{
            @"Content-Type": mimeType,
            @"Content-Length": [NSString stringWithFormat:@"%ld", responseData.length],
            @"Access-Control-Allow-Origin": @"*"
        };
        
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL 
                                                                  statusCode:200 
                                                                 HTTPVersion:@"HTTP/1.1" 
                                                                headerFields:responseHeaders];
        
        // Log resource loading
        NSLog(@"Loaded resource: %@ (MIME: %@)", urlString, mimeType);
        
        // Send response to WebView
        @try {
            [urlSchemeTask didReceiveResponse:response];
            [urlSchemeTask didReceiveData:responseData];
            [urlSchemeTask didFinish];
        } @catch (NSException *exception) {
            NSLog(@"Error handling URL scheme task: %@", exception.reason);
        }
    }];

}

/**
 * Handles stopping a URL scheme task
 * @param webView The WKWebView that initiated the task
 * @param urlSchemeTask The task to be stopped
 */
- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask { 
    // Clean up any resources associated with this task
    NSLog(@"Stopping URL scheme task: %@", urlSchemeTask.request.URL.absoluteString);
}

/**
 * Determines the MIME type for a given file path
 * @param path The file path
 * @return The MIME type string
 */
- (NSString *)mimeTypeForPath:(NSString *)path {
    // Return appropriate MIME type based on file path
    NSString *extension = [[path pathExtension] lowercaseString];
    
    // Use a dictionary for faster lookup
    static NSDictionary *mimeTypes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mimeTypes = @{
            @"html": @"text/html",
            @"htm": @"text/html",
            @"css": @"text/css",
            @"js": @"application/javascript",
            @"json": @"application/json",
            @"xml": @"application/xml",
            @"png": @"image/png",
            @"jpg": @"image/jpeg",
            @"jpeg": @"image/jpeg",
            @"gif": @"image/gif",
            @"svg": @"image/svg+xml",
            @"ico": @"image/x-icon",
            @"txt": @"text/plain",
            @"pdf": @"application/pdf",
            @"mp3": @"audio/mpeg",
            @"mp4": @"video/mp4",
            @"webp": @"image/webp",
            @"woff": @"font/woff",
            @"woff2": @"font/woff2",
            @"ttf": @"font/ttf",
            @"otf": @"font/otf",
            @"eot": @"application/vnd.ms-fontobject"
        };
    });
    
    NSString *mimeType = mimeTypes[extension];
    return mimeType ?: @"application/octet-stream";
}

/**
 * Gets cached file data based on URL
 * @param URLString The URL string of the resource
 * @param completion Completion block with the cached data
 */
- (void)getCacheDataByURL:(NSString *)URLString AndCompletion:(nullable void (^)(NSData * result1))completion {
    if (!URLString || URLString.length == 0) {
        NSLog(@"Error: Invalid URL string");
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    NSURL *URL = [NSURL URLWithString:URLString];
    NSString *fullPath = URL.path;
    
    NSString *fileNameWithExtension = [fullPath lastPathComponent];
    NSString *fileNameWithoutExtension = [[fullPath lastPathComponent] stringByDeletingPathExtension];
    NSString *fileExtension = [fullPath pathExtension];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileNameWithoutExtension ofType:fileExtension];
    
    if (!filePath) {
        NSLog(@"File not found: %@", fileNameWithExtension);
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    NSError *error = nil;
    NSData *cacheData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
    
    if (error) {
        NSLog(@"Error reading file: %@", error.localizedDescription);
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    if (completion) {
        completion(cacheData);
    }
}
/**
 * Checks if the file type is supported
 * @param urlString The URL string to check
 * @return YES if the file type is supported, NO otherwise
 */
- (BOOL)isSupportedFileType:(NSString *)urlString {
    return [urlString containsString:@".html"] ||
           [urlString containsString:@".js"] ||
           [urlString containsString:@".css"] ||
           [urlString containsString:@".jpg"] ||
           [urlString containsString:@".png"] ||
           [urlString containsString:@".jpeg"] ||
           [urlString containsString:@".gif"];
}

/**
 * Handles unsupported file types
 * @param urlSchemeTask The URL scheme task
 * @param request The URL request
 */
- (void)handleUnsupportedFileType:(id<WKURLSchemeTask>)urlSchemeTask withRequest:(NSURLRequest *)request {
    NSString *errorMessage = [NSString stringWithFormat:@"Unsupported file type: %@", request.URL.absoluteString];
    NSLog(@"%@", errorMessage);
    
    NSData *errorData = [errorMessage dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *headers = @{
        @"Content-Type": @"text/plain",
        @"Content-Length": [NSString stringWithFormat:@"%ld", errorData.length]
    };
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL 
                                                              statusCode:415 
                                                             HTTPVersion:@"HTTP/1.1" 
                                                            headerFields:headers];
    
    @try {
        [urlSchemeTask didReceiveResponse:response];
        [urlSchemeTask didReceiveData:errorData];
        [urlSchemeTask didFinish];
    } @catch (NSException *exception) {
        NSLog(@"Error handling unsupported file type: %@", exception.reason);
    }
}

/**
 * Handles resource not found errors
 * @param urlSchemeTask The URL scheme task
 * @param request The URL request
 * @param urlString The URL string that was not found
 */
- (void)handleResourceNotFound:(id<WKURLSchemeTask>)urlSchemeTask withRequest:(NSURLRequest *)request urlString:(NSString *)urlString {
    NSString *errorMessage = [NSString stringWithFormat:@"Resource not found: %@", urlString];
    NSLog(@"%@", errorMessage);
    
    NSData *errorData = [errorMessage dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *headers = @{
        @"Content-Type": @"text/plain",
        @"Content-Length": [NSString stringWithFormat:@"%ld", errorData.length]
    };
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL 
                                                              statusCode:404 
                                                             HTTPVersion:@"HTTP/1.1" 
                                                            headerFields:headers];
    
    @try {
        [urlSchemeTask didReceiveResponse:response];
        [urlSchemeTask didReceiveData:errorData];
        [urlSchemeTask didFinish];
    } @catch (NSException *exception) {
        NSLog(@"Error handling resource not found: %@", exception.reason);
    }
}
@end
