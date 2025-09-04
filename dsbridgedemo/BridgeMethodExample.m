//
//  BridgeMethodExample.m
//  dsbridgedemo
//
//  Created by Example on 2024
//  Copyright © 2024 Example. All rights reserved.
//

#import "BridgeMethodExample.h"
#import "DWKWebView.h"

@implementation BridgeMethodExample

+ (void)setupBridgeMethods:(DWKWebView *)webView {
    
    // 示例1: 注册一个全局的bridge方法
    [webView registerBridgeMethod:@"showAlert" 
                         handler:^(NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"来自JS的消息" 
                                                                         message:message 
                                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" 
                                                              style:UIAlertActionStyleDefault 
                                                            handler:nil];
            [alert addAction:okAction];
            
            UIViewController *topVC = [self topViewController];
            [topVC presentViewController:alert animated:YES completion:nil];
        });
    } namespace:nil];
    
    // 示例2: 注册一个带命名空间的bridge方法
    [webView registerBridgeMethod:@"getDeviceInfo" 
                         handler:^(void (^completion)(NSString *)) {
        NSString *deviceInfo = [NSString stringWithFormat:@"设备: %@, 系统: %@", 
                               [[UIDevice currentDevice] model],
                               [[UIDevice currentDevice] systemVersion]];
        completion(deviceInfo);
    } namespace:@"device"];
    
    // 示例3: 注册一个异步的bridge方法
    [webView registerBridgeMethod:@"asyncOperation" 
                         handler:^(NSString *data, void (^completion)(NSString *)) {
        // 模拟异步操作
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), 
                      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *result = [NSString stringWithFormat:@"处理完成: %@", data];
            completion(result);
        });
    } namespace:@"async"];
    
    // 示例4: 注册一个返回值的bridge方法
    [webView registerBridgeMethod:@"calculate" 
                         handler:^(NSNumber *a, NSNumber *b, NSString *operation) {
        double result = 0;
        if ([operation isEqualToString:@"add"]) {
            result = [a doubleValue] + [b doubleValue];
        } else if ([operation isEqualToString:@"subtract"]) {
            result = [a doubleValue] - [b doubleValue];
        } else if ([operation isEqualToString:@"multiply"]) {
            result = [a doubleValue] * [b doubleValue];
        } else if ([operation isEqualToString:@"divide"]) {
            if ([b doubleValue] != 0) {
                result = [a doubleValue] / [b doubleValue];
            }
        }
        return @(result);
    } namespace:@"math"];
}

// 获取顶层视图控制器的辅助方法
+ (UIViewController *)topViewController {
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [self topViewControllerWithRootViewController:rootViewController];
}

+ (UIViewController *)topViewControllerWithRootViewController:(UIViewController *)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        return [self topViewControllerWithRootViewController:rootViewController.presentedViewController];
    }
    return rootViewController;
}

@end
