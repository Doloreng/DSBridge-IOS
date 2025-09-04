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
    
    // Add the method to the class dynamically
    class_addMethod([self class], 
                   NSSelectorFromString(methodName), 
                   (IMP)dynamicMethodIMP, 
                   "v@:@");
}

- (BOOL)hasMethod:(NSString *)methodName {
    return [self.methodHandlers objectForKey:methodName] != nil;
}

- (NSArray<NSString *> *)registeredMethodNames {
    return [self.methodHandlers allKeys];
}

// Dynamic method implementation that forwards calls to the stored handler
static id dynamicMethodIMP(id self, SEL _cmd, ...) {
    DSBridgeMethodProxy *proxy = (DSBridgeMethodProxy *)self;
    NSString *methodName = NSStringFromSelector(_cmd);
    id handler = [proxy.methodHandlers objectForKey:methodName];
    
    if (handler) {
        // Get the arguments
        va_list args;
        va_start(args, _cmd);
        
        // For simplicity, we'll handle common cases
        // In a real implementation, you might want to parse the method signature
        // and handle different argument types properly
        
        // Try to call the handler as a block
        if ([handler isKindOfClass:NSClassFromString(@"NSBlock")]) {
            // This is a simplified implementation
            // In practice, you'd need to handle different block signatures
            return handler;
        }
        
        va_end(args);
    }
    
    return nil;
}

// Override forwardInvocation to handle method calls
- (void)forwardInvocation:(NSInvocation *)invocation {
    NSString *methodName = NSStringFromSelector([invocation selector]);
    id handler = [self.methodHandlers objectForKey:methodName];
    
    if (handler) {
        // Handle the invocation based on the handler type
        if ([handler isKindOfClass:NSClassFromString(@"NSBlock")]) {
            // Handle block-based handlers
            [self handleBlockInvocation:invocation withHandler:handler];
        } else {
            // Handle object-based handlers
            [invocation invokeWithTarget:handler];
        }
    } else {
        [super forwardInvocation:invocation];
    }
}

- (void)handleBlockInvocation:(NSInvocation *)invocation withHandler:(id)handler {
    // This is a simplified implementation
    // In practice, you'd need to parse the block signature and handle arguments properly
    // For now, we'll just log that the method was called
    
    NSString *methodName = NSStringFromSelector([invocation selector]);
    NSLog(@"DSBridge: Method '%@' called with handler", methodName);
    
    // You could implement more sophisticated argument handling here
    // based on the block signature and invocation arguments
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSString *methodName = NSStringFromSelector(aSelector);
    if ([self hasMethod:methodName]) {
        // Return a generic method signature
        // In practice, you might want to analyze the block signature
        return [NSMethodSignature signatureWithObjCTypes:"@@:"];
    }
    return [super methodSignatureForSelector:aSelector];
}

@end
