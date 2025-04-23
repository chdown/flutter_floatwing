/// window size
///
class WindowSize {
  static const int MatchParent = -1;
  static const int WrapContent = -2;
}

enum GravityType {
  Center,
  CenterTop,
  CenterBottom,
  LeftTop,
  LeftCenter,
  LeftBottom,
  RightTop,
  RightCenter,
  RightBottom,

  Unknown,
}

extension GravityTypeConverter on GravityType {

  // 0001 0001
  static const Center = 17;
  // 0011 0000
  static const Top = 48;
  // 0101 0000
  static const Bottom = 80;
  // 0000 0011
  static const Left = 3;
  // 0000 0101
  static const Right = 5;

  static final _values = {
    GravityType.Center: Center,
    GravityType.CenterTop: Top | Center,
    GravityType.CenterBottom: Bottom | Center,
    GravityType.LeftTop: Top | Left,
    GravityType.LeftCenter: Center | Left,
    GravityType.LeftBottom: Bottom | Left,
    GravityType.RightTop: Top | Right,
    GravityType.RightCenter: Center | Right,
    GravityType.RightBottom: Bottom | Right,
  };

  int? toInt() {
    return _values[this];
  }

  GravityType? fromInt(int? v) {
    if (v == null) return null;
    var r = _values.keys
        .firstWhere((e) => _values[e] == v, orElse: () => GravityType.Unknown);
    return r == GravityType.Unknown ? null : r;
  }
}
