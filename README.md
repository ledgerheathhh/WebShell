# WebShell

## Project Overview
WebShell is an iOS application that uses WKWebView to load and display web content, with custom URL protocol handling functionality. The app allows loading local HTML resources through custom protocols (such as QuantumLink://), providing a more flexible way to load web content in iOS applications.

## Main Features
- Support for loading local HTML resources via custom URL protocol (QuantumLink://)
- Support for loading online web content (http/https)
- Support for loading local HTML files via File protocol
- Progress bar showing webpage loading progress
- Automatic handling of various resource types (HTML, CSS, JavaScript, images, etc.)

## Technical Implementation

### SchemeHandler
The core of the project is a custom URL protocol handler (SchemeHandler) that implements the WKURLSchemeHandler protocol, allowing WKWebView to handle non-standard URL protocols.

Main components:
- **SchemeHandler**: Implements the WKURLSchemeHandler protocol to handle custom URL requests
- **WKWebView+SchemeHandler**: WKWebView category extension for handling URL protocols

### How It Works
1. Register the custom URL protocol handler in WKWebViewConfiguration
2. When WKWebView encounters a custom protocol URL (e.g., QuantumLink://), it calls the SchemeHandler to process it
3. SchemeHandler looks up local resources (HTML, CSS, JS, images, etc.) based on the URL path
4. Converts local resources to the appropriate response format and returns them to WKWebView

### Example Usage
```objective-c
// Configure WKWebView to use custom protocol in ViewController
WKWebViewConfiguration *wkWebConfig = [[WKWebViewConfiguration alloc] init];
if (@available(iOS 11.0, *)) {
    [wkWebConfig setURLSchemeHandler:SchemeHandler.new forURLScheme:@"QuantumLink"];
}

// Create WKWebView and load custom protocol URL
WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:wkWebConfig];

// Use custom protocol to load webpage
NSURL *url = [NSURL URLWithString:@"QuantumLink://www.ledgerheath.com/index.html"];
NSURLRequest *request = [NSURLRequest requestWithURL:url];
[webView loadRequest:request];
```

## Project Structure
- **WebShell/**: Main project directory
  - **SchemeHandler/**: Custom URL protocol handling related files
    - SchemeHandler.h/m: Implements WKURLSchemeHandler protocol
    - WKWebView+SchemeHandler.h/m: WKWebView category extension
  - **JL/**: Sample HTML resource directory
    - index.html: Home page
    - blog_*.html: Blog pages
    - static/: Static resources (CSS, JS, images, etc.)
  - **ViewController.h/m**: Main view controller
  - **AppDelegate.h/m**: Application delegate
  - **SceneDelegate.h/m**: Scene delegate

## System Requirements
- iOS 11.0+ (requires WKURLSchemeHandler support)
- Xcode 12.0+

## Usage Instructions
1. Clone or download the project code
2. Open WebShell.xcodeproj with Xcode
3. Build and run the project
4. The app will load the sample page (Justice League theme)

## Customization
To use this project as a foundation for your own application:
1. Replace the HTML resources in the JL directory with your own web content
2. Modify the URL loading method in ViewController.m as needed
3. If you need to change the custom protocol name, modify all occurrences of "QuantumLink"

## Notes
- The custom protocol handler is only available in iOS 11.0 and above
- Local resources must be included in the application bundle to be loaded correctly
- Ensure that relative paths in HTML resources correctly reference other resources (CSS, JS, images, etc.)