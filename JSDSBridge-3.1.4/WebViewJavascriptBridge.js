var bridge = {
    default: this, // for typescript
    
    // 添加namespace配置
    _namespaces: {
        // 默认配置的四个命名空间
        'control': {
            'back_to_home': true,
            'network_send_request': true
        },
        'system': {
            'system_miaobo_info': true,
            'logger_upload_analyze_info': true
        },
        'live': {
            'Platform_OpenUrl': true,
            'Platform_CallMethod': true,
            'Platform_ClearCookie': true,
            'Platform_SyncCookie': true,
            'Platform_switch_stage': true,
            'Platform_switch_streamUrl': true,
            'Platform_preload_resources': true,
            'Platform_ShowWindow': true,
            'Platform_RefreshWindow': true,
            'Platform_HideWindow': true,
            'Platform_CloseWindow': true,
            'Platform_ShowToast': true,
            'Platform_InnerLink': true,
            'Platform_HyperLink': true,
            'Platform_DisplayLiveRoom': true,
            'Platform_KeepWebAlive' : true,
            'Platform_CMD_ReloadConfig' : true,
            'Platform_CMD_ReloadRtc' : true,
            'Platform_CMD_StopLive' : true,
            'Platform_ShutDown_ClientPushStream' : true,
            'Platform_StopDisplay' : true,
            'Platform_Switch_Live_Statistics' : true,
            'Platform_Switch_Voice_Source' : true,
            'set_back_stoplive' : true,
            'sync_local_storage' : true,
            'Platform_start_PiP' : true,
            'Platform_stop_PiP' : true,
            'Platform_Get_Cookie' : true,
            'download_by_browser' : true
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
    
    callHandler: function (method, args, cb) {
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
    
    registerHandler: function (name, fun) {
        // 默认就是异步，直接使用 _dsaf
        var q = window._dsaf;
        if (!window._dsInit) {
            window._dsInit = true;
            // notify native that js apis register successfully on next event loop
            setTimeout(function () {
                bridge.callHandler("_dsb.dsinit");
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
        return this.callHandler("_dsb.hasNativeMethod", { name: fullMethod, type: type || "all" });
    },
    
    disableJavascriptDialogBlock: function (disable) {
        this.callHandler("_dsb.disableJavascriptDialogBlock", {
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
            bridge.callHandler("_dsb.closePage");
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
                bridge.callHandler("_dsb.returnValue", ret);
            };
            
            var callAsyn = function (f, ob) {
                arg.push(function (data, complete) {
                    ret.data = data;
                    ret.complete = complete !== false;
                    bridge.callHandler("_dsb.returnValue", ret);
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
    
    bridge.registerHandler("_hasJavascriptMethod", function (method, tag) {
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
try {
    window.WebViewJavascriptBridge = bridge;
    window.console.log('WebViewJavascriptBridge initialized successfully');
} catch (error) {
    window.console.error('Failed to initialize WebViewJavascriptBridge:', error);
}
