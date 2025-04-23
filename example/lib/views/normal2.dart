import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

class NonrmalView2 extends StatefulWidget {
  const NonrmalView2({Key? key}) : super(key: key);

  @override
  State<NonrmalView2> createState() => _NonrmalView2State();
}

class _NonrmalView2State extends State<NonrmalView2> {
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
      print("Normal2 window initialized with id: ${w?.id}");
      
      w?.on(EventType.WindowDragStart, (window, data) {
        if (mounted) setState(() => {dragging = true});
      }).on(EventType.WindowDragEnd, (window, data) {
        if (mounted) setState(() => {dragging = false});
      });

      // 设置数据接收处理器
      w?.onData((source, name, data) async {
        print("Normal2 received message from $source: $data");
        if (mounted) {
          setState(() {
            _messages.add("收到来自 $source 的消息: $data");
            if (_messages.length > 5) {
              _messages.removeAt(0);
            }
          });
        }
        return "normal2窗口已收到消息";
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
      print("Normal2 sending message to $targetId");
      var response = await w?.share(
        "这是来自 normal2 窗口的消息",
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
      print("Normal2 message sending error: $e");
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
                  Text("Normal2窗口", 
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
                        onPressed: () => _sendMessage("normal1"),
                        child: Text("发 normal1"),
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
