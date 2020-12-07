#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

extern NSString * const  POST_BACK_URL;

@protocol D3DSDelegate
@required
-(void) authorizationCompletedWithMD: (NSString *) md andPares: (NSString *) paRes;
-(void) authorizationFailedWithHtml: (NSString *) html;
@end

@interface D3DS : NSObject <WKNavigationDelegate>
{
    id<D3DSDelegate> d3DSDelegate;
    WKWebView *webView;
}
-(void) make3DSPaymentWithUIViewController: (UIViewController<D3DSDelegate> *) viewController andAcsURLString: (NSString *) acsUrlString andPaReqString: (NSString *) paReqString andTransactionIdString: (NSString *) transactionIdString;
-(void) make3DSPaymentWithUIViewController: (UIViewController *) viewController delegate:(id<D3DSDelegate>)delegate andAcsURLString: (NSString *) acsUrlString andPaReqString: (NSString *) paReqString andTransactionIdString: (NSString *) transactionIdString;

@end
