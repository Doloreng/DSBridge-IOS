//
//  DSBridgeMethodProxy.m
//  dsbridge
//
//  Created by DSBridge on 2024
//  Copyright © 2024 DSBridge. All rights reserved.
//

#import "DSBridgeMethodProxy.h"
#import <objc/runtime.h>

@interface DSBridgeMethodProxy ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *methodHandlers;
@end

@implementation DSBridgeMethodProxy


- (instancetype)init {
   self = [super init];
   if (self) {
       _methodHandlers = [NSMutableDictionary dictionary];
   }
   return self;
}

- (void)registerMethod:(NSString *)methodName withHandler:(id)handler {
   if (methodName == nil || handler == nil) {
       return;
   }
   
   // Store the handler
   [self.methodHandlers setObject:handler forKey:methodName];
   
   // 为方法添加两个参数的方法签名，参考LXSZJSBAccoutAPIs的实现
   // 格式: methodName:params:responseCallback
   NSString *fullMethodName = [NSString stringWithFormat:@"%@::", methodName];
   SEL methodSel = NSSelectorFromString(fullMethodName);
   
   if (!class_getInstanceMethod([self class], methodSel)) {
       class_addMethod([self class],
                      methodSel,
                      (IMP)dynamicMethodIMP,
                      "v@:@@");
   }
}

- (BOOL)hasMethod:(NSString *)methodName {
   return [self.methodHandlers objectForKey:methodName] != nil;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
   NSString *methodName = NSStringFromSelector(aSelector);
   
   // 检查是否是 methodName:: 格式的方法
   if ([methodName hasSuffix:@"::"]) {
       NSString *baseMethodName = [methodName stringByReplacingOccurrencesOfString:@"::" withString:@""];
       if ([self hasMethod:baseMethodName]) {
           return YES;
       }
   }
   
   return [super respondsToSelector:aSelector];
}

- (NSArray<NSString *> *)registeredMethodNames {
   return [self.methodHandlers allKeys];
}

// 动态方法实现，处理 methodName:params:responseCallback 格式的调用
static void dynamicMethodIMP(id self, SEL _cmd, id params, id responseCallback) {
    DSBridgeMethodProxy *proxy = (DSBridgeMethodProxy *)self;
    NSString *methodName = NSStringFromSelector(_cmd);
    // 移除末尾的 :: 得到基础方法名
    methodName = [methodName stringByReplacingOccurrencesOfString:@"::" withString:@""];
    
    id handler = [proxy.methodHandlers objectForKey:methodName];
    
    if (handler && [handler isKindOfClass:NSClassFromString(@"NSBlock")]) {
        // 调用block，传递参数和回调
        void (^block)(id, id) = (void (^)(id, id))handler;
        block(params, responseCallback);
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
   NSString *methodName = NSStringFromSelector(aSelector);
   
   // 检查是否是 methodName:: 格式的方法
   if ([methodName hasSuffix:@"::"]) {
       NSString *baseMethodName = [methodName stringByReplacingOccurrencesOfString:@"::" withString:@""];
       if ([self hasMethod:baseMethodName]) {
           // 返回 v@:@@ 签名，对应 void methodName:(id)params :(id)responseCallback
           return [NSMethodSignature signatureWithObjCTypes:"v@:@@"];
       }
   }
   
   return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
   NSString *methodName = NSStringFromSelector([invocation selector]);
   
   // 检查是否是 methodName:: 格式的方法
   if ([methodName hasSuffix:@"::"]) {
       NSString *baseMethodName = [methodName stringByReplacingOccurrencesOfString:@"::" withString:@""];
       if ([self hasMethod:baseMethodName]) {
           id params = nil;
           id responseCallback = nil;
           [invocation getArgument:&params atIndex:2];
           [invocation getArgument:&responseCallback atIndex:3];
           
           id handler = [self.methodHandlers objectForKey:baseMethodName];
           if ([handler isKindOfClass:NSClassFromString(@"NSBlock")]) {
               void (^block)(id, id) = (void (^)(id, id))handler;
               block(params, responseCallback);
           }
           return;
       }
   }
   
   [super forwardInvocation:invocation];
}


@end
