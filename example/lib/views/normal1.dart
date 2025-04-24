import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

class NonrmalView1 extends StatefulWidget {
  const NonrmalView1({Key? key}) : super(key: key);

  @override
  State<NonrmalView1> createState() => _NonrmalView1State();
}

class _NonrmalView1State extends State<NonrmalView1> {
  bool _expend = false;
  double _size = 300;
  Window? w;
  bool dragging = false;
  List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      w = Window.of(context);
      print("Normal1 window initialized with id: ${w?.id}");
      
      w?.on(EventType.WindowDragStart, (window, data) {
        if (mounted) setState(() => {dragging = true});
      }).on(EventType.WindowDragEnd, (window, data) {
        if (mounted) setState(() => {dragging = false});
      });

      // 设置数据接收处理器
      w?.onData((source, name, data) async {
        print("Normal1 received message from $source: $data");
        if (mounted) {
          setState(() {
            _messages.add("收到来自 $source 的消息: $data");
            if (_messages.length > 5) {
              _messages.removeAt(0);
            }
          });
        }
        return "normal1窗口已收到消息";
      });
    });
  }

  _changeSize() {
    _expend = !_expend;
    _size = _expend ? 400 : 300;
    setState(() {});
  }

  _sendMessage(String targetId) async {
    try {
      print("Normal1 sending message to $targetId");
      var response = await w?.share(
        "这是来自 normal1 窗口的消息",
        targetId: targetId,
      );
      if (mounted) {
        setState(() {
          _messages.add("发送到 $targetId 的消息已收到回复: $response");
          if (_messages.length > 5) {
            _messages.removeAt(0);
          }
        });
      }
    } catch (e) {
      print("Normal1 message sending error: $e");
      if (mounted) {
        setState(() {
          _messages.add("发送到 $targetId 的消息失败: $e");
          if (_messages.length > 5) {
            _messages.removeAt(0);
          }
        });
      }
    }
  }

  _sendToMainApp() async {
    try {
      print("Normal1 sending message to main app");
      // 使用 FloatwingPlugin 发送消息到主应用
      var response = await FloatwingPlugin().sendToMainApp({
        "source": w?.id ?? "normal1",
        "data": "这是来自 normal1 窗口发送到主应用的消息",
        "name": "toMainApp",
      });
      
      if (mounted) {
        setState(() {
          _messages.add("发送到主应用的消息已发送，响应: $response");
          if (_messages.length > 5) {
            _messages.removeAt(0);
          }
        });
      }
    } catch (e) {
      print("Normal1 sending to main app error: $e");
      if (mounted) {
        setState(() {
          _messages.add("发送到主应用的消息失败: $e");
          if (_messages.length > 5) {
            _messages.removeAt(0);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: _size,
        height: _size,
        color: dragging ? Colors.yellowAccent : null,
        child: Card(
          child: Stack(
            children: [
              Column(
                children: [
                  Text("Normal1窗口", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  // 消息显示区域
                  Expanded(
                    child: ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(_messages[index], 
                            style: TextStyle(fontSize: 12)),
                        );
                      },
                    ),
                  ),
                  // 发送消息按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _sendMessage("normal"),
                        child: Text("发 normal"),
                      ),
                      ElevatedButton(
                        onPressed: () => _sendMessage("normal2"),
                        child: Text("发 normal2"),
                      ),
                      ElevatedButton(
                        onPressed: () => _sendToMainApp(),
                        child: Text("发送到主应用"),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          WindowConfig(
                            id: "normal2",
                            route: "/normal2",
                            draggable: true,
                            autosize: true,
                          ).to().create(start: true);
                        },
                        child: Text("创建 normal2"),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(right: 5, top: 5, child: Icon(Icons.drag_handle_rounded)),
              Positioned(
                right: 5,
                bottom: 5,
                child: RotationTransition(
                  turns: AlwaysStoppedAnimation(-45 / 360),
                  child: InkWell(
                    onTap: _changeSize,
                    child: Icon(Icons.unfold_more_rounded)
                  )
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
