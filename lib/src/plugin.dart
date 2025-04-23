import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

class FloatwingPlugin {
  FloatwingPlugin._() {
    WidgetsFlutterBinding.ensureInitialized();
  }

  static const String channelID = "im.zoe.labs/flutter_floatwing";

  static final MethodChannel _channel = MethodChannel('$channelID/method');

  static final FloatwingPlugin _instance = FloatwingPlugin._();

  bool _inited = false;
  Map<String, Window> _windows = {};
  Window? _window;
  bool _isWindow = false;

  Map<String, Window> get windows => _windows;
  Window? get currentWindow => _window;
  bool get isWindow => _isWindow;

  factory FloatwingPlugin() {
    return _instance;
  }

  FloatwingPlugin get instance {
    return _instance;
  }

  Future<bool> syncWindows() async {
    var _ws = await _channel.invokeListMethod("plugin.sync_windows");
    _ws?.forEach((e) {
      var w = Window.fromMap(e);
      _windows[w.id] = w;
    });
    return true;
  }

  Future<bool> initialize() async {
    if (_inited) return false;
    _inited = true;

    var map = await _channel.invokeMapMethod("plugin.initialize", {
      "pixelRadio": window.devicePixelRatio,
      "system": SystemConfig().toMap(),
    });

    log("[plugin] initialize result: $map");

    var _ws = map?["windows"] as List<dynamic>?;
    _ws?.forEach((e) {
      var w = Window.fromMap(e);
      _windows[w.id] = w;
    });

    log("[plugin] there are ${_windows.length} windows already started");

    return true;
  }

  Future<bool> checkPermission() async {
    return await _channel.invokeMethod("plugin.has_permission");
  }

  Future<bool> openPermissionSetting() async {
    return await _channel.invokeMethod("plugin.open_permission_setting");
  }

  Future<bool> isServiceRunning() async {
    return await _channel.invokeMethod("plugin.is_service_running");
  }

  Future<bool> startService() async {
    return await _channel.invokeMethod("plugin.start_service");
  }

  Future<bool> cleanCache() async {
    return await _channel.invokeMethod("plugin.clean_cache");
  }

  Future<Window?> createWindow(
    String? id,
    WindowConfig config, {
    bool start = false,
    Window? window,
  }) async {
    var w = isWindow
        ? await currentWindow?.createChildWindow(id, config, start: start, window: window)
        : await internalCreateWindow(id, config, start: start, window: window, channel: _channel);
    if (w == null) return null;
    _windows[w.id] = w;
    return w;
  }

  Future<Window?> internalCreateWindow(
    String? id,
    WindowConfig config, {
    bool start = false,
    Window? window,
    required MethodChannel channel,
    String name = "plugin.create_window",
  }) async {
    if (!await checkPermission()) {
      throw Exception("no permission to create window");
    }

    var updates = await channel.invokeMapMethod(name, {
      "id": id,
      "config": config.toMap(),
      "start": start,
    });
    return updates == null ? null : (window ?? Window()).applyMap(updates);
  }

  Future<Window?> ensureWindow() async {
    var map = await Window.sync();
    log("[window] sync window object from android: $map");
    if (map == null) return null;
    if (_window == null) _window = Window();
    _window!.applyMap(map);
    _isWindow = true;
    return _window;
  }
}
