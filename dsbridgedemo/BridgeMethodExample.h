//
//  BridgeMethodExample.h
//  dsbridgedemo
//
//  Created by Example on 2024
//  Copyright © 2024 Example. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DWKWebView;

@interface BridgeMethodExample : NSObject

/**
 * 设置bridge方法的示例
 * @param webView 需要设置bridge方法的DWKWebView实例
 */
+ (void)setupBridgeMethods:(DWKWebView *)webView;

@end
