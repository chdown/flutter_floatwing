import 'package:flutter/material.dart';

import 'package:flutter_floatwing/flutter_floatwing.dart';
import 'package:flutter_floatwing_example/views/assistive_touch.dart';
import 'package:flutter_floatwing_example/views/night.dart';
import 'package:flutter_floatwing_example/views/normal.dart';
import 'package:flutter_floatwing_example/views/normal1.dart';
import 'package:flutter_floatwing_example/views/normal2.dart';

void main() {
  runApp(MyApp());
}

@pragma("vm:entry-point")
void floatwing() {
  runApp(((_) => NonrmalView()).floatwing().make());
}

void floatwing2(Window w) {
  runApp(MaterialApp(
    // floatwing on widget can't use Window.of(context)
    // to access window instance
    // should use FloatwingPlugin().currentWindow
    home: NonrmalView().floatwing(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _configs = [
    WindowConfig(
      id: "normal",
      // entry: "floatwing",
      route: "/normal",
      draggable: true,
      width: 600,
      height: 600,
      autosize: false,
    ),
    WindowConfig(
      id: "normal1",
      // entry: "floatwing",
      route: "/normal1",
      draggable: true,
      autosize: true,
    ),
    WindowConfig(
      id: "assitive_touch",
      // entry: "floatwing",
      route: "/assitive_touch",
      autosize: true,
      draggable: true,
    ),
    WindowConfig(
      id: "night",
      // entry: "floatwing",
      route: "/night",
      autosize: true,
      width: WindowSize.MatchParent,
      height: WindowSize.MatchParent,
      clickable: false,
    )
  ];

  Map<String, WidgetBuilder> _builders = {
    "normal": (_) => NonrmalView(),
    "normal1": (_) => NonrmalView1(),
    "assitive_touch": (_) => AssistiveTouch(),
    "night": (_) => NightView(),
  };

  Map<String, Widget Function(BuildContext)> _routes = {};

  @override
  void initState() {
    super.initState();

    _routes["/"] = (_) => HomePage(configs: _configs);
    _routes["/normal2"] = (_) => NonrmalView2().floatwing();

    _configs.forEach((c) => {
          if (c.route != null && _builders[c.id] != null) {_routes[c.route!] = _builders[c.id]!.floatwing(debug: false)}
        });
        
    // 初始化FloatwingPlugin
    FloatwingPlugin().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: _routes,
    );
  }
}

class HomePage extends StatefulWidget {
  final List<WindowConfig> configs;

  const HomePage({Key? key, required this.configs}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    widget.configs.forEach((c) => _windows.add(c.to()));

    // 注册主应用消息处理器
    FloatwingPlugin().setMainAppMessageHandler(_handleFloatwingMessage);

    initAsyncState();
  }

  // 处理来自悬浮窗的消息
  void _handleFloatwingMessage(String? source, String name, dynamic data) {
    print("主应用收到消息: $data");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("收到来自 $source 的消息: $data"),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  List<Window> _windows = [];

  Map<Window, bool> _readys = {};

  bool _ready = false;

  initAsyncState() async {
    var p1 = await FloatwingPlugin().checkPermission();
    var p2 = await FloatwingPlugin().isServiceRunning();

    // get permission first
    if (!p1) {
      FloatwingPlugin().openPermissionSetting();
      return;
    }

    // start service
    if (!p2) {
      FloatwingPlugin().startService();
    }

    _createWindows();

    setState(() {
      _ready = true;
    });
  }

  _createWindows() async {
    await FloatwingPlugin().isServiceRunning().then((v) async {
      if (!v)
        await FloatwingPlugin().startService().then((_) {
          print("start the backgroud service success.");
        });
    });

    _windows.forEach((w) {
      var _w = FloatwingPlugin().windows[w.id];
      if (null != _w) {
        // replace w with _w
        _readys[w] = true;
        return;
      }
      w.on(EventType.WindowCreated, (window, data) {
        _readys[window] = true;
        setState(() {});
      }).create();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floatwing example app'),
      ),
      body: _ready
          ? ListView(
              children: _windows.map((e) => _item(e)).toList(),
            )
          : Center(
              child: ElevatedButton(
                  onPressed: () {
                    initAsyncState();
                  },
                  child: Text("Start")),
            ),
    );
  }

  _debug(Window w) {
    Navigator.of(context).pushNamed(w.config!.route!);
  }

  Widget _item(Window w) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Text(w.id, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(color: Color.fromARGB(255, 214, 213, 213), borderRadius: BorderRadius.all(Radius.circular(4))),
                child: Text(w.config?.toString() ?? ""),
              ),
              SizedBox(height: 10),
              Wrap(
                children: [
                  TextButton(
                    onPressed: (_readys[w] == true) ? () => w.start() : null,
                    child: Text("Open"),
                  ),
                  TextButton(onPressed: w.config?.route != null ? () => _debug(w) : null, child: Text("Debug")),
                  TextButton(
                    onPressed: (_readys[w] == true) ? () => {w.close(), w.share("close")} : null,
                    child: Text("Close", style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: (_readys[w] == true) ? () => {w.show(visible: false), w.share("close")} : null,
                    child: Text("Hide", style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: (_readys[w] == true) ? () => {w.show(visible: true), w.share("close")} : null,
                    child: Text("Show", style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: (_readys[w] == true) ? () => _sendMessage(w) : null,
                    child: Text("send"),
                  ),
                ],
              )
            ],
          )),
    );
  }

  _sendMessage(Window w) async {
    try {
      // 发送消息到指定窗口
      final result = await w.share(
        "这是一条来自主应用的消息",
        name: "test",
        targetId: w.id,
      );
      print("消息发送结果: $result");
    } catch (e) {
      print("发送消息失败: $e");
    }
  }
}
