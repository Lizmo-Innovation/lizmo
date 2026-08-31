import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// How much to grow type on this particular screen.
///
/// Two different things make text bigger, and they are not alternatives:
///
/// 1. The reader's own font-size setting, which Flutter applies to every [Text]
///    through MediaQuery.textScaler. Nothing here interferes with it — this
///    multiplies what the design asks for, and the reader's preference is then
///    applied on top. Somebody who has turned their phone's text up gets both.
/// 2. The size of the screen, which is what this is for: a 6.7" phone has room
///    for larger type than a 5", and rendering both at the same 14px wastes the
///    bigger one.
extension LizmoScale on BuildContext {

  /// The width the type scale was drawn against: a standard 390pt phone.
  static const _baseWidth = 390.0;

  /// Never below 1. On a narrow phone the answer to "this is hard to read" is
  /// never to shrink it further — the layout gives way instead.
  static const _min = 1.0;

  /// And never runaway on a tablet, where the same factor applied to a 1024pt
  /// width would produce headings the size of a fist.
  static const _max = 1.35;

  /// Multiply a design font size by this.
  ///
  /// Deliberately gentle: the shortest side rather than the width, so turning a
  /// phone sideways does not resize the words on it, and the square root of the
  /// ratio so that a screen 30% wider gets about 14% larger type rather than
  /// 30%. Type that grows in step with the canvas stops looking designed.
  double get lizmoTextScale {
    final size = MediaQuery.sizeOf(this);
    final shortest = size.shortestSide;
    if (shortest <= 0) return _min;
    final ratio = shortest / _baseWidth;
    return math.sqrt(ratio).clamp(_min, _max);
  }

  /// A design size, scaled for this screen.
  double lizmoSize(double designSize) => designSize * lizmoTextScale;
}
