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
    
    NSURLRequest *request = urlSchemeTask.request;
    NSString *urlString = request.URL.absoluteString;
    NSDictionary *headerField = request.allHTTPHeaderFields;
    NSMutableDictionary *HeaderField = [[NSMutableDictionary alloc] initWithDictionary:headerField];
    if ([HeaderField objectForKey:@"Access-Control-Allow-Origin"]) {
        
    }else{
        [HeaderField setObject:@"*" forKey:@"Access-Control-Allow-Origin"];
    }
    
    __block NSHTTPURLResponse *response = nil;
    
    //When HTML switch is on and it's an HTML file, use HTML cache logic
    if ([urlString containsString:@".html"]) {
        /// Local HTML resources
        [self getCacheDataByURL:urlString AndCompletion:^(NSData *result) {
            NSData *responseObject =result;
            NSString *mimeType = @"text/html";
            NSData *responseObjectData = (NSData *)responseObject;
            
            NSDictionary *headerFields = @{
                @"Content-Type":[NSString stringWithFormat:@"%@", mimeType],
                @"Content-Length":[NSString stringWithFormat:@"%ld", responseObjectData.length]
            };
            response = [[NSHTTPURLResponse alloc]initWithURL:request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headerFields];
            
            if (responseObject) {
                NSLog(@"Task loaded local cached HTML - %@ -",urlString);
                
                @try {
                    [urlSchemeTask didReceiveResponse:response];
                    [urlSchemeTask didReceiveData:responseObject];
                    [urlSchemeTask didFinish];
                } @catch (NSException *exception) {
                    NSLog(@"This request stopped = crash will occur here 97");
                } @finally {
                    
                }
                return;
            }
        }];
        
    }else if ([urlString containsString:@".js"] ||
              [urlString containsString:@".css"] ||
              [urlString containsString:@".jpg"] ||
              [urlString containsString:@".png"] ||
              [urlString containsString:@".jpeg"] ||
              [urlString containsString:@".gif"]) {
        /// Local non-HTML resources
        NSString *mimeType = [self mimeTypeForPath:urlString];
        [self getCacheDataByURL:urlString AndCompletion:^(NSData *result) {
            NSData *responseObject =result;
            if ([responseObject isKindOfClass:[NSData class]]) {
                NSData *responseObjectData = (NSData *)responseObject;
                
                NSDictionary *headerFields = @{
                    @"Content-Type":[NSString stringWithFormat:@"%@", mimeType],
                    @"Content-Length":[NSString stringWithFormat:@"%ld", responseObjectData.length]
                };
                response = [[NSHTTPURLResponse alloc]initWithURL:request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headerFields];
                NSLog(@"Request cached locally by WKWebView - %@",response.URL.absoluteString);
                
                @try {
                    [urlSchemeTask didReceiveResponse:response];
                    [urlSchemeTask didReceiveData:responseObject];
                    [urlSchemeTask didFinish];
                } @catch (NSException *exception) {
                    NSLog(@"This request stopped = crash will occur here 97");
                } @finally {
                    
                }
                return;
            }
        }];
        
    }

}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask { 
    
}

- (NSString *)mimeTypeForPath:(NSString *)path {
    // Return appropriate MIME type based on file path
    NSString *extension = [path pathExtension];
    if ([extension isEqualToString:@"html"]) {
        return @"text/html";
    } else if ([extension isEqualToString:@"css"]) {
        return @"text/css";
    } else if ([extension isEqualToString:@"js"]) {
        return @"application/javascript";
    } else if ([extension isEqualToString:@"png"]) {
        return @"image/png";
    } else if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
        return @"image/jpeg";
    } else {
        return @"application/octet-stream";
    }
}

//Get cached file data based on URL
- (void)getCacheDataByURL:(NSString *)URLString AndCompletion:(nullable void (^)(NSData * result1))completion {
    NSURL *URL = [NSURL URLWithString:URLString];
    NSString *fullPath = URL.path;
//    NSString *directoryPath = [fullPath stringByDeletingLastPathComponent];
    
    NSString *fileNameWithExtension = [fullPath lastPathComponent];
    NSString *fileNameWithoutExtension = [[fullPath lastPathComponent] stringByDeletingPathExtension];
    NSString *fileExtension = [fullPath pathExtension];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileNameWithoutExtension ofType:fileExtension];
    
    NSData *cacheData = nil;
    NSError *error = nil;
    if (error) {
        NSLog(@"Error reading file: %@", error.localizedDescription);
    } else {
        if(filePath){
            cacheData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&error];
            if(completion){
                completion(cacheData);
            }
        }else {
            NSLog(@"File:%@ Not Exist", fileNameWithExtension);
        }
    }
}
@end
