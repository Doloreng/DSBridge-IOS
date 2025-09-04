//
//  PerformanceComparisonExample.h
//  dsbridgedemo
//
//  Created by Example on 2024
//  Copyright © 2024 Example. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DWKWebView;

@interface PerformanceComparisonExample : NSObject

/**
 * 运行完整的性能测试
 * @param webView 要测试的DWKWebView实例
 */
+ (void)performanceTest:(DWKWebView *)webView;

/**
 * 演示效率优化效果
 * @param webView 要演示的DWKWebView实例
 */
+ (void)demonstrateEfficiency:(DWKWebView *)webView;

@end
