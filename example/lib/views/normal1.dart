import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_floatwing/flutter_floatwing.dart';

class NonrmalView1 extends StatefulWidget {
  const NonrmalView1({Key? key}) : super(key: key);

  @override
  State<NonrmalView1> createState() => _NonrmalViewState();
}

class _NonrmalViewState extends State<NonrmalView1> {
  bool _expend = false;
  double _size = 300;

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
    });
  }

  Window? w;
  bool dragging = false;

  _changeSize() {
    _expend = !_expend;
    _size = _expend ? 400 : 300;
    setState(() {});
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
                Text("Normal1"),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      WindowConfig(
                        id: "normal2",
                        // entry: "floatwing",
                        route: "/normal2",
                        draggable: true,
                        autosize: true,
                      ).to().create(start: true);
                    },
                    child: Text("Start Normal2"),
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      w?.share("data");
                    },
                    child: Text("Start 1"),
                  ),
                ),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // w?.share("data",targetId: "assitive_touch");
                      w?.share("data");
                    },
                    child: Text("Start 2"),
                  ),
                )
              ],
            ),
            Positioned(right: 5, top: 5, child: Icon(Icons.drag_handle_rounded)),
            Positioned(
                right: 5,
                bottom: 5,
                child: RotationTransition(turns: AlwaysStoppedAnimation(-45 / 360), child: InkWell(onTap: _changeSize, child: Icon(Icons.unfold_more_rounded))))
          ],
        )),
      ),
    );
  }
}
