# DSBridge 方法注册扩展

## 概述

为DSWKWebView扩展了一个新的方法 `registerBridgeMethod`，允许原生代码动态注册单个bridge方法，而无需创建完整的JavaScript接口对象。

**优化说明**: 新版本使用共享的代理对象来管理所有注册的方法，避免了每次调用都创建新对象的内存浪费问题。

## 新增方法

### 主要方法

#### registerBridgeMethod

```objc
- (void)registerBridgeMethod:(NSString *)methodName 
                     handler:(id)handler 
                   namespace:(NSString *)namespace;
```

**参数说明：**

- `methodName`: 要注册的方法名称（必填）
- `handler`: 处理方法的block（必填）
- `namespace`: 方法的命名空间（可选，nil表示全局命名空间）

### 便利方法

#### hasBridgeMethod

```objc
- (BOOL)hasBridgeMethod:(NSString *)methodName namespace:(NSString *)namespace;
```

检查指定命名空间中是否存在指定的bridge方法。

#### getBridgeMethodNamesInNamespace

```objc
- (NSArray<NSString *> *)getBridgeMethodNamesInNamespace:(NSString *)namespace;
```

获取指定命名空间中所有已注册的bridge方法名称。

#### removeBridgeMethod

```objc
- (void)removeBridgeMethod:(NSString *)methodName namespace:(NSString *)namespace;
```

从指定命名空间中移除指定的bridge方法。

## 使用方法

### 1. 基本用法

```objc
#import "DWKWebView.h"

// 注册一个全局方法
[webView registerBridgeMethod:@"showAlert" 
                     handler:^(NSString *message) {
    // 处理逻辑
    NSLog(@"收到消息: %@", message);
} namespace:nil];

// 注册一个带命名空间的方法
[webView registerBridgeMethod:@"getDeviceInfo" 
                     handler:^(void (^completion)(NSString *)) {
    NSString *info = [NSString stringWithFormat:@"设备: %@", 
                      [[UIDevice currentDevice] model]];
    completion(info);
} namespace:@"device"];
```

### 2. 管理已注册的方法

```objc
// 检查方法是否存在
BOOL hasMethod = [webView hasBridgeMethod:@"showAlert" namespace:nil];

// 获取所有方法名称
NSArray *methods = [webView getBridgeMethodNamesInNamespace:@"device"];

// 移除方法
[webView removeBridgeMethod:@"showAlert" namespace:nil];
```

### 3. 异步方法

```objc
[webView registerBridgeMethod:@"asyncOperation" 
                     handler:^(NSString *data, void (^completion)(NSString *)) {
    // 在后台线程执行
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 模拟耗时操作
        NSString *result = [NSString stringWithFormat:@"处理完成: %@", data];
        completion(result);
    });
} namespace:@"async"];
```

### 4. 返回值方法

```objc
[webView registerBridgeMethod:@"calculate" 
                     handler:^(NSNumber *a, NSNumber *b, NSString *operation) {
    double result = 0;
    if ([operation isEqualToString:@"add"]) {
        result = [a doubleValue] + [b doubleValue];
    }
    return @(result);
} namespace:@"math"];
```

## JavaScript调用方式

### 全局方法

```javascript
// 调用全局方法
window.dsBridge.call('showAlert', 'Hello World');
```

### 命名空间方法

```javascript
// 调用带命名空间的方法
window.dsBridge.call('device.getDeviceInfo', '', function(result) {
    console.log('设备信息:', result);
});

// 异步方法调用
window.dsBridge.call('async.asyncOperation', '测试数据', function(result) {
    console.log('异步结果:', result);
});

// 同步方法调用
const result = window.dsBridge.call('math.calculate', [10, 5, 'add']);
console.log('计算结果:', result);
```

## 性能优化

### 共享代理对象

- 每个命名空间只创建一个 `DSBridgeMethodProxy` 对象
- 所有方法都注册到同一个代理对象上
- 避免了重复创建对象的内存浪费

### 内存管理

- 使用 `NSMutableDictionary` 高效存储方法处理器
- 支持动态添加和移除方法
- 自动管理对象生命周期

## 完整示例

参考 `BridgeMethodExample.m` 文件，其中包含了各种使用场景的完整示例代码。

## 注意事项

1. **方法名称**: 方法名称不能为nil，且应该具有描述性
2. **Handler**: Handler不能为nil，可以是block或方法实现
3. **命名空间**: 命名空间为nil时表示全局命名空间
4. **线程安全**: 在handler中执行UI操作时，请确保在主线程执行
5. **内存管理**: 注意避免循环引用，特别是在block中使用self时
6. **性能**: 新版本使用共享代理对象，大大减少了内存分配

## 与现有方法的区别

- **addJavascriptObject**: 注册整个对象，对象的所有方法都会暴露给JavaScript
- **registerBridgeMethod**: 只注册单个方法，更加灵活和轻量级，使用共享代理对象优化内存使用

## 适用场景

- 需要动态添加单个bridge方法
- 不想创建完整的JavaScript接口对象
- 需要更细粒度的控制
- 临时性的bridge方法需求
- 对内存使用有要求的场景

## 测试

使用 `bridge-test.html` 文件来测试新注册的bridge方法功能。
