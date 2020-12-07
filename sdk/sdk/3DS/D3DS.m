#import "D3DS.h"

@interface D3DS (Private)
@end

NSString * const POST_BACK_URL = @"https://demo.cloudpayments.ru/WebFormPost/GetWebViewData";

@implementation D3DS

-(void) make3DSPaymentWithUIViewController: (UIViewController<D3DSDelegate> *) viewController andAcsURLString: (NSString *) acsUrlString andPaReqString: (NSString *) paReqString andTransactionIdString: (NSString *) transactionIdString {
    [self make3DSPaymentWithUIViewController:viewController delegate:viewController andAcsURLString:acsUrlString andPaReqString:paReqString andTransactionIdString:transactionIdString];
}

-(void) make3DSPaymentWithUIViewController: (UIViewController *) viewController delegate:(id<D3DSDelegate>)delegate andAcsURLString: (NSString *) acsUrlString andPaReqString: (NSString *) paReqString andTransactionIdString: (NSString *) transactionIdString {
    d3DSDelegate = delegate;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: acsUrlString]];
    [request setHTTPMethod: @"POST"];
    [request setCachePolicy: NSURLRequestReloadIgnoringCacheData];
    NSMutableString *requestBody;
    requestBody = [NSMutableString stringWithString: @"MD="];
    [requestBody appendString: transactionIdString];
    [requestBody appendString: @"&PaReq="];
    [requestBody appendString: paReqString];
    [requestBody appendString: @"&TermUrl="];
    [requestBody appendString: POST_BACK_URL];
    [request setHTTPBody:[[requestBody stringByReplacingOccurrencesOfString: @"+" withString: @"%2B"] dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"Request body %@", [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding]);

    [[NSURLCache sharedURLCache] removeCachedResponseForRequest: request];
    
    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (([(NSHTTPURLResponse *)response statusCode] == 200 || [(NSHTTPURLResponse *)response statusCode] == 201)) {
                WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
                self->webView = [[WKWebView alloc] initWithFrame:viewController.view.frame configuration:configuration];
                [self->webView setNavigationDelegate: self];
                [viewController.view addSubview:self->webView];
                [self->webView loadData:data MIMEType:[response MIMEType] characterEncodingName:[response textEncodingName] baseURL:[response URL]];
            } else {
                NSString *messageString = [NSString stringWithFormat:@"Unable to load 3DS autorization page.\nStatus code: %d", (unsigned int)[(NSHTTPURLResponse *)response statusCode]];
                [delegate authorizationFailedWithHtml:messageString];
            }
        });
    }] resume];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
    NSURL *url = webView.URL;
    if ([url.absoluteString isEqualToString:POST_BACK_URL]) {
        __weak typeof(self) wself = self;
        [webView evaluateJavaScript:@"document.documentElement.outerHTML.toString()" completionHandler:^(NSString *_Nullable result, NSError * _Nullable error) {
            __strong typeof(wself) sself = wself;
            NSString *str = result;
            do {
                NSRange startRange = [str rangeOfString:@"{"];
                if (startRange.location == NSNotFound) {
                    break;
                }
                str = [str substringFromIndex:startRange.location];
                NSRange endRange = [str rangeOfString:@"}"];
                if (endRange.location == NSNotFound) {
                    break;
                }
                str = [str substringToIndex:endRange.location + 1];
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
                [sself->d3DSDelegate authorizationCompletedWithMD:dict[@"MD"] andPares:dict[@"PaRes"]];
                [webView removeFromSuperview];
                return;
            } while(NO);
            [sself->d3DSDelegate authorizationFailedWithHtml:str];
            [webView removeFromSuperview];
        }];
    } 
}

@end
