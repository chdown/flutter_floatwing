import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_floatwing/flutter_floatwing.dart';

typedef OnDataHanlder = Future<dynamic> Function(String? source, String? name, dynamic data);

class Window {
  String id = "default";
  WindowConfig? config;

  double? pixelRadio;
  SystemConfig? system;
  OnDataHanlder? _onDataHandler;

  late EventManager _eventManager;

  Window({this.id = "default", this.config}) {
    _eventManager = EventManager(_message, window: this);

    // share data use the call
    _channel.setMethodCallHandler((call) {
      switch (call.method) {
        case "data.share":
          {
            var map = call.arguments as Map<dynamic, dynamic>;
            // source, name, data
            // if not provided, should not call this
            return _onDataHandler?.call(map["source"], map["name"], map["data"]) ?? Future.value(null);
          }
      }
      return Future.value(null);
    });
  }

  static final MethodChannel _channel = MethodChannel('${FloatwingPlugin.channelID}/window');
  static final BasicMessageChannel _message = BasicMessageChannel('${FloatwingPlugin.channelID}/window_msg', JSONMessageCodec());

  factory Window.fromMap(Map<dynamic, dynamic>? map) {
    return Window().applyMap(map);
  }

  @override
  String toString() {
    return "Window[$id]@${super.hashCode}, ${_eventManager.toString()}, config: $config";
  }

  Window applyMap(Map<dynamic, dynamic>? map) {
    // apply the map to config and object
    if (map == null) return this;
    id = map["id"];
    pixelRadio = map["pixelRadio"] ?? 1.0;
    system = SystemConfig.fromMap(map["system"] ?? {});
    config = WindowConfig.fromMap(map["config"]);
    return this;
  }

  /// `of` extact window object window from context
  /// The data from the closest instance of this class that encloses the given
  /// context.
  static Window? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FloatwingProvider>()?.window;
  }

  Future<bool?> hide() {
    return show(visible: false);
    // return FloatwingPlugin().showWindow(id, false);
  }

  Future<bool?> close({bool force = false}) async {
    // return await FloatwingPlugin().closeWindow(id, force: force);
    return await _channel.invokeMethod("window.close", {
      "id": id,
      "force": force,
    }).then((v) {
      // remove the window from plugin
      FloatwingPlugin().windows.remove(id);
      return v;
    });
  }

  Future<Window?> create({bool start = false}) async {
    // // create the engine first
    return await FloatwingPlugin().createWindow(this.id, this.config!, start: start, window: this);
  }

  /// create child window
  /// just method shoudld only called in window engine
  Future<Window?> createChildWindow(
    String? id,
    WindowConfig config, {
    bool start = false, // start immediately if true
    Window? window,
  }) async {
    return FloatwingPlugin().internalCreateWindow(id, config, start: start, window: window, channel: _channel, name: "window.create_child");
  }

  Future<bool?> start() async {
    assert(config != null, "config can't be null");
    return await _channel.invokeMethod("window.start", {
      "id": id,
    });
    // return await FloatwingPlugin().startWindow(id);
  }

  Future<bool> update(WindowConfig cfg) async {
    // update window with config, config con't update with id, entry, route
    var size = config?.size;
    if (size != null && size < Size.zero) {
      // special case, should updated
      cfg.width = null;
      cfg.height = null;
    }
    var updates = await _channel.invokeMapMethod("window.update", {
      "id": id,
      // don't set pixelRadio
      "config": cfg.toMap(),
    });
    // var updates = await FloatwingPlugin().updateWindow(id, cfg);
    // update the plugin store
    applyMap(updates);
    return true;
  }

  Future<bool?> show({bool visible = true}) async {
    config?.visible = visible;
    return await _channel.invokeMethod("window.show", {
      "id": id,
      "visible": visible,
    }).then((v) {
      // update the plugin store
      if (v) FloatwingPlugin().windows[id]?.config?.visible = visible;
      return v;
    });
  }

  /// share data with current window
  /// send data use current window id as target id
  /// and get value return
  Future<dynamic> share(
    dynamic data, {
    String name = "default",
    String? targetId,
  }) async {
    var map = {};
    map["target"] = targetId ?? id;
    map["data"] = data;
    map["name"] = name;
    // make sure data is serialized
    return await _channel.invokeMethod("data.share", map);
  }

  /// launch main activity
  Future<bool> launchMainActivity() async {
    return await _channel.invokeMethod("window.launch_main");
  }

  /// on data to receive data from other shared
  /// maybe same like event handler
  /// but one window in engine can only have one data handler
  /// to make sure data not be comsumed multiple times.
  Window onData(OnDataHanlder handler) {
    assert(_onDataHandler == null, "onData can only called once");
    _onDataHandler = handler;
    return this;
  }

  // sync window object from android service
  // only window engine call this
  // if we manage other windows in some window engine
  // this will not works, we must improve it
  static Future<Map<dynamic, dynamic>?> sync() async {
    return await _channel.invokeMapMethod("window.sync");
  }

  /// on register callback to listener
  Window on(EventType type, WindowListener callback) {
    _eventManager.on(this, type, callback);
    return this;
  }

  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map["id"] = id;
    map["pixelRadio"] = pixelRadio;
    map["config"] = config?.toMap();
    return map;
  }
}

class WindowConfig {
  String? id;

  String? entry;
  String? route;
  Function? callback; // use callback to start engine

  bool? autosize;

  int? width;
  int? height;
  int? x;
  int? y;

  int? format;
  GravityType? gravity;
  int? type;

  bool? clickable;
  bool? draggable;
  bool? focusable;

  /// immersion status bar
  bool? immersion;

  bool? visible;

  double? marginVertical;
  double? offsetX;

  /// we need this for update, so must wihtout default value
  WindowConfig({
    this.id = "default",
    this.entry = "main",
    this.route,
    this.callback,
    this.autosize,
    this.width,
    this.height,
    this.x,
    this.y,
    this.format,
    this.gravity,
    this.type,
    this.clickable,
    this.draggable,
    this.focusable,
    this.immersion,
    this.visible,
    this.marginVertical,
    this.offsetX,
  }) : assert(callback == null || PluginUtilities.getCallbackHandle(callback) != null, "callback is not a static function");

  factory WindowConfig.fromMap(Map<dynamic, dynamic> map) {
    var _cb;
    if (map["callback"] != null) _cb = PluginUtilities.getCallbackFromHandle(CallbackHandle.fromRawHandle(map["callback"]));
    return WindowConfig(
      // id: map["id"],
      entry: map["entry"],
      route: map["route"],
      callback: _cb,
      // get the callback from id

      autosize: map["autosize"],

      width: map["width"],
      height: map["height"],
      x: map["x"],
      y: map["y"],

      format: map["format"],
      gravity: GravityType.Unknown.fromInt(map["gravity"]),
      type: map["type"],

      clickable: map["clickable"],
      draggable: map["draggable"],
      focusable: map["focusable"],

      immersion: map["immersion"],

      visible: map["visible"],

      marginVertical: map["marginVertical"],
      offsetX: map["offsetX"],
    );
  }

  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    // map["id"] = id;
    map["entry"] = entry;
    map["route"] = route;
    // find the callback id from callback function
    map["callback"] = callback != null ? PluginUtilities.getCallbackHandle(callback!)?.toRawHandle() : null;

    map["autosize"] = autosize;

    map["width"] = width;
    map["height"] = height;
    map["x"] = x;
    map["y"] = y;

    map["format"] = format;
    map["gravity"] = gravity?.toInt();
    map["type"] = type;

    map["clickable"] = clickable;
    map["draggable"] = draggable;
    map["focusable"] = focusable;

    map["immersion"] = immersion;

    map["visible"] = visible;

    map["marginVertical"] = marginVertical;
    map["offsetX"] = offsetX;

    return map;
  }

  // return a window frm config
  Window to() {
    // will lose window instance
    return Window(id: this.id ?? "default", config: this);
  }

  Future<Window?> create({
    String? id = "default",
    bool start = false,
  }) async {
    assert(!(entry == "main" && route == null));
    return await FloatwingPlugin().createWindow(id, this, start: start);
  }

  Size get size => Size((width ?? 0).toDouble(), (height ?? 0).toDouble());

  @override
  String toString() {
    var map = this.toMap();
    map.removeWhere((key, value) => value == null);
    return json.encode(map).toString();
  }
}
