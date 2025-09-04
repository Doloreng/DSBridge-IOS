var bridge = {
    default: this, // for typescript
    
    // 添加namespace配置
    _namespaces: {
        // 默认配置的四个命名空间
        'control': {
            'play': true,
            'pause': true,
            'stop': true,
            'next': true,
            'prev': true,
            'seek': true,
            'setVolume': true,
            'getVolume': true,
            'mute': true,
            'unmute': true
        },
        'system': {
            'getDeviceInfo': true,
            'getAppVersion': true,
            'getSystemInfo': true,
            'exitApp': true,
            'restartApp': true,
            'clearCache': true,
            'getBatteryLevel': true,
            'getNetworkStatus': true
        },
        'live': {
            'startLive': true,
            'stopLive': true,
            'switchCamera': true,
            'setFlash': true,
            'setResolution': true,
            'getLiveStatus': true,
            'setBeauty': true,
            'setFilter': true
        },
        'proxy': {
            'getProxyList': true,
            'setProxy': true,
            'clearProxy': true,
            'testProxy': true,
            'getCurrentProxy': true,
            'switchProxy': true
        }
    },
    
    // 配置namespace
    configureNamespace: function (namespace, methods) {
        if (typeof methods === 'object') {
            this._namespaces[namespace] = methods;
        }
    },
    
    // 获取方法的完整路径（包含namespace）
    _getFullMethodName: function (method) {
        // 如果方法名已经包含namespace，直接返回
        if (method.indexOf('.') !== -1) {
            return method;
        }
        
        // 查找方法属于哪个namespace
        for (var namespace in this._namespaces) {
            if (this._namespaces[namespace] && this._namespaces[namespace][method]) {
                return namespace + '.' + method;
            }
        }
        
        // 如果没有找到namespace，返回原方法名
        return method;
    },
    
    call: function (method, args, cb) {
        var ret = '';
        if (typeof args == 'function') {
            cb = args;
            args = {};
        }
        
        var arg = { data: args === undefined ? null : args };
        if (typeof cb == 'function') {
            var cbName = 'dscb' + window.dscb++;
            window[cbName] = cb;
            arg['_dscbstub'] = cbName;
        }
        arg = JSON.stringify(arg);
        
        // 获取完整的方法名（包含namespace）
        var fullMethod = this._getFullMethodName(method);
        
        // if in webview that dsBridge provided, call!
        if (window._dsbridge) {
            ret = _dsbridge.call(fullMethod, arg);
        } else if (window._dswk || navigator.userAgent.indexOf("_dsbridge") != -1) {
            ret = prompt("_dsbridge=" + fullMethod, arg);
        }
        
        return JSON.parse(ret || '{}').data;
    },
    
    register: function (name, fun) {
        // 默认就是异步，直接使用 _dsaf
        var q = window._dsaf;
        if (!window._dsInit) {
            window._dsInit = true;
            // notify native that js apis register successfully on next event loop
            setTimeout(function () {
                bridge.call("_dsb.dsinit");
            }, 0);
        }
        if (typeof fun == "object") {
            q._obs[name] = fun;
        } else {
            q[name] = fun;
        }
    },
    
    hasNativeMethod: function (name, type) {
        // 获取完整的方法名（包含namespace）
        var fullMethod = this._getFullMethodName(name);
        return this.call("_dsb.hasNativeMethod", { name: fullMethod, type: type || "all" });
    },
    
    disableJavascriptDialogBlock: function (disable) {
        this.call("_dsb.disableJavascriptDialogBlock", {
            disable: disable !== false
        });
    }
};

!function () {
    if (window._dsf) return;
    
    var ob = {
        _dsf: {
            _obs: {}
        },
        _dsaf: {
            _obs: {}
        },
        dscb: 0,
        dsBridge: bridge,
        
        close: function () {
            bridge.call("_dsb.closePage");
        },
        
        _handleMessageFromNative: function (info) {
            var arg = JSON.parse(info.data);
            var ret = {
                id: info.callbackId,
                complete: true
            };
            
            var f = this._dsf[info.method];
            var af = this._dsaf[info.method];
            
            var callSyn = function (f, ob) {
                ret.data = f.apply(ob, arg);
                bridge.call("_dsb.returnValue", ret);
            };
            
            var callAsyn = function (f, ob) {
                arg.push(function (data, complete) {
                    ret.data = data;
                    ret.complete = complete !== false;
                    bridge.call("_dsb.returnValue", ret);
                });
                f.apply(ob, arg);
            };
            
            if (f) {
                callSyn(f, this._dsf);
            } else if (af) {
                callAsyn(af, this._dsaf);
            } else {
                // with namespace
                var name = info.method.split('.');
                if (name.length < 2) return;
                
                var method = name.pop();
                var namespace = name.join('.');
                var obs = this._dsf._obs;
                var ob = obs[namespace] || {};
                var m = ob[method];
                
                if (m && typeof m == "function") {
                    callSyn(m, ob);
                    return;
                }
                
                obs = this._dsaf._obs;
                ob = obs[namespace] || {};
                m = ob[method];
                
                if (m && typeof m == "function") {
                    callAsyn(m, ob);
                    return;
                }
            }
        }
    };
    
    for (var attr in ob) {
        window[attr] = ob[attr];
    }
    
    bridge.register("_hasJavascriptMethod", function (method, tag) {
        var name = method.split('.');
        if (name.length < 2) {
            return !!(_dsf[name] || _dsaf[name]);
        } else {
            // with namespace
            var method = name.pop();
            var namespace = name.join('.');
            var ob = _dsf._obs[namespace] || _dsaf._obs[namespace];
            return ob && !!ob[method];
        }
    });
}();

// 将bridge暴露到全局作用域，通过window.WebViewJavascriptBridge访问
window.WebViewJavascriptBridge = bridge;
