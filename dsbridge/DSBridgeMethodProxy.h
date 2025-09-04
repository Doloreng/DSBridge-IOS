//
//  DSBridgeMethodProxy.h
//  dsbridge
//
//  Created by DSBridge on 2024
//  Copyright © 2024 DSBridge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DSBridgeMethodProxy : NSObject

/**
 * Register a method with the given name and handler
 * @param methodName The name of the method
 * @param handler The block that implements the method
 */
- (void)registerMethod:(NSString *)methodName withHandler:(id)handler;

/**
 * Check if a method exists
 * @param methodName The name of the method to check
 * @return YES if the method exists, NO otherwise
 */
- (BOOL)hasMethod:(NSString *)methodName;

/**
 * Get all registered method names
 * @return Array of method names
 */
- (NSArray<NSString *> *)registeredMethodNames;

@end
