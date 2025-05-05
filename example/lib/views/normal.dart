import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

class NonrmalView extends StatefulWidget {
  const NonrmalView({Key? key}) : super(key: key);

  @override
  State<NonrmalView> createState() => _NonrmalViewState();
}

class _NonrmalViewState extends State<NonrmalView> {
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
      w?.on(EventType.WindowDragStart, (window, data) {
        if (mounted) setState(() => {dragging = true});
      }).on(EventType.WindowDragEnd, (window, data) {
        if (mounted) setState(() => {dragging = false});
      });

      // 设置数据接收处理器
      w?.onData((source, name, data) async {
        if (mounted) {
          setState(() {
            _messages.add("收到来自 $source 的消息: $data");
            if (_messages.length > 5) {
              _messages.removeAt(0);
            }
          });
        }
        return "normal窗口已收到消息";
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
      var response = await w?.share(
        "这是来自 normal 窗口的消息",
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
    return Container(
      // width: _size,
      // height: _size,
      color: dragging ? Colors.yellowAccent : null,
      child: Card(
        child: Stack(
          children: [
            Column(
              children: [
                Text("Normal窗口", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                // 消息显示区域
                Expanded(
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(_messages[index], style: TextStyle(fontSize: 12)),
                      );
                    },
                  ),
                ),
                // 发送消息按钮
                Wrap(
                  children: [
                    ElevatedButton(
                      onPressed: () => _sendMessage("normal"),
                      child: Text("发 normal"),
                    ),
                    ElevatedButton(
                      onPressed: () => _sendMessage("normal1"),
                      child: Text("发 normal1"),
                    ),
                    ElevatedButton(
                      onPressed: () => _sendMessage("normal2"),
                      child: Text("发 normal2"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        WindowConfig? config = w?.config;
                        config?.width = WindowSize.MatchParent;
                        config?.height = WindowSize.MatchParent;
                        if (config != null) {
                          w?.update(config);
                        }
                      },
                      child: Text("full"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        WindowConfig? config = w?.config;
                        config?.width = WindowSize.WrapContent;
                        config?.height = WindowSize.WrapContent;
                        if (config != null) {
                          w?.update(config);
                        }
                      },
                      child: Text("small"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        bool isShow = await w?.isShow("normal1") ?? false;
                        print("=================$isShow");
                      },
                      child: Text("isShow"),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(right: 5, top: 5, child: Icon(Icons.drag_handle_rounded)),
            Positioned(
                right: 5,
                bottom: 5,
                child:
                    RotationTransition(turns: AlwaysStoppedAnimation(-45 / 360), child: InkWell(onTap: _changeSize, child: Icon(Icons.unfold_more_rounded)))),
          ],
        ),
      ),
    );
  }
}
