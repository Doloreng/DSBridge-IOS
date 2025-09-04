//
//  PerformanceComparisonExample.m
//  dsbridgedemo
//
//  Created by Example on 2024
//  Copyright © 2024 Example. All rights reserved.
//

#import "PerformanceComparisonExample.h"
#import "DWKWebView.h"
#import <mach/mach_time.h>

@implementation PerformanceComparisonExample

+ (void)performanceTest:(DWKWebView *)webView {
    NSLog(@"开始性能测试...");
    
    // 测试1: 注册多个方法到不同命名空间
    [self testMultipleNamespaces:webView];
    
    // 测试2: 注册大量方法到同一命名空间
    [self testManyMethodsInSameNamespace:webView];
    
    // 测试3: 内存使用对比
    [self testMemoryUsage:webView];
}

+ (void)testMultipleNamespaces:(DWKWebView *)webView {
    NSLog(@"\n=== 测试1: 多个命名空间 ===");
    
    uint64_t startTime = mach_absolute_time();
    
    // 注册到不同命名空间
    for (int i = 0; i < 10; i++) {
        NSString *namespace = [NSString stringWithFormat:@"ns%d", i];
        [webView registerBridgeMethod:[NSString stringWithFormat:@"method%d", i] 
                             handler:^(NSString *param) {
            NSLog(@"命名空间 %@ 的方法被调用: %@", namespace, param);
        } namespace:namespace];
    }
    
    uint64_t endTime = mach_absolute_time();
    uint64_t elapsed = endTime - startTime;
    
    NSLog(@"注册10个命名空间耗时: %llu 纳秒", elapsed);
    
    // 检查对象数量
    NSArray *methods1 = [webView getBridgeMethodNamesInNamespace:@"ns0"];
    NSArray *methods2 = [webView getBridgeMethodNamesInNamespace:@"ns1"];
    NSLog(@"命名空间 ns0 中的方法数量: %lu", (unsigned long)methods1.count);
    NSLog(@"命名空间 ns1 中的方法数量: %lu", (unsigned long)methods2.count);
}

+ (void)testManyMethodsInSameNamespace:(DWKWebView *)webView {
    NSLog(@"\n=== 测试2: 同一命名空间大量方法 ===");
    
    uint64_t startTime = mach_absolute_time();
    
    // 注册大量方法到同一命名空间
    for (int i = 0; i < 100; i++) {
        [webView registerBridgeMethod:[NSString stringWithFormat:@"bulkMethod%d", i] 
                             handler:^(NSString *param) {
            NSLog(@"批量方法 %d 被调用: %@", i, param);
        } namespace:@"bulk"];
    }
    
    uint64_t endTime = mach_absolute_time();
    uint64_t elapsed = endTime - startTime;
    
    NSLog(@"注册100个方法到同一命名空间耗时: %llu 纳秒", elapsed);
    
    // 检查方法数量
    NSArray *methods = [webView getBridgeMethodNamesInNamespace:@"bulk"];
    NSLog(@"bulk命名空间中的方法数量: %lu", (unsigned long)methods.count);
}

+ (void)testMemoryUsage:(DWKWebView *)webView {
    NSLog(@"\n=== 测试3: 内存使用对比 ===");
    
    // 获取当前内存使用情况
    struct task_basic_info info;
    mach_msg_type_number_t size = TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    
    if (kerr == KERN_SUCCESS) {
        NSLog(@"当前内存使用: %llu KB", info.resident_size / 1024);
    }
    
    // 注册更多方法
    NSLog(@"注册更多方法...");
    for (int i = 0; i < 50; i++) {
        [webView registerBridgeMethod:[NSString stringWithFormat:@"memoryTest%d", i] 
                             handler:^(NSString *param) {
            // 空实现，只测试内存使用
        } namespace:@"memory"];
    }
    
    // 再次获取内存使用情况
    kerr = task_info(mach_task_self(),
                     TASK_BASIC_INFO,
                     (task_info_t)&info,
                     &size);
    
    if (kerr == KERN_SUCCESS) {
        NSLog(@"注册50个方法后内存使用: %llu KB", info.resident_size / 1024);
    }
}

+ (void)demonstrateEfficiency:(DWKWebView *)webView {
    NSLog(@"\n=== 效率演示 ===");
    
    // 演示：多次调用registerBridgeMethod不会创建新对象
    NSLog(@"第一次注册方法...");
    [webView registerBridgeMethod:@"efficiencyTest" 
                         handler:^(NSString *param) {
        NSLog(@"效率测试方法被调用: %@", param);
    } namespace:@"efficiency"];
    
    NSLog(@"第二次注册方法到同一命名空间...");
    [webView registerBridgeMethod:@"efficiencyTest2" 
                         handler:^(NSString *param) {
        NSLog(@"效率测试方法2被调用: %@", param);
    } namespace:@"efficiency"];
    
    NSLog(@"第三次注册方法到同一命名空间...");
    [webView registerBridgeMethod:@"efficiencyTest3" 
                         handler:^(NSString *param) {
        NSLog(@"效率测试方法3被调用: %@", param);
    } namespace:@"efficiency"];
    
    // 检查命名空间中的方法数量
    NSArray *methods = [webView getBridgeMethodNamesInNamespace:@"efficiency"];
    NSLog(@"efficiency命名空间中的方法数量: %lu", (unsigned long)methods.count);
    
    // 验证方法是否都存在
    BOOL hasMethod1 = [webView hasBridgeMethod:@"efficiencyTest" namespace:@"efficiency"];
    BOOL hasMethod2 = [webView hasBridgeMethod:@"efficiencyTest2" namespace:@"efficiency"];
    BOOL hasMethod3 = [webView hasBridgeMethod:@"efficiencyTest3" namespace:@"efficiency"];
    
    NSLog(@"方法1存在: %@", hasMethod1 ? @"是" : @"否");
    NSLog(@"方法2存在: %@", hasMethod2 ? @"是" : @"否");
    NSLog(@"方法3存在: %@", hasMethod3 ? @"是" : @"否");
}

@end
