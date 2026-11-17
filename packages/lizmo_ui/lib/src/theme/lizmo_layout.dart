import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// How much room a screen has, in the three sizes the layouts change at.
///
/// The Material breakpoints: under 600 is a phone, 600 to 839 a tablet held
/// upright, 840 and up a tablet on its side or anything wider.
enum LizmoWidth {
  compact,
  medium,
  expanded;

  static LizmoWidth of(double width) => width >= 840
      ? LizmoWidth.expanded
      : width >= 600
          ? LizmoWidth.medium
          : LizmoWidth.compact;
}

/// The width a page's content is laid out in, set by the shell that holds it.
///
/// A tablet's side rail takes room the page does not get, so the page cannot
/// read its width from the screen. The shell measures what is left and says
/// so here; a screen outside any shell falls back to the screen's width.
class PageArea extends StatelessWidget {
  const PageArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _PageWidth(
        width: constraints.maxWidth,
        child: child,
      ),
    );
  }
}

class _PageWidth extends InheritedWidget {
  const _PageWidth({required this.width, required super.child});

  final double width;

  @override
  bool updateShouldNotify(_PageWidth old) => old.width != width;
}

extension LizmoLayout on BuildContext {
  /// The widest a column of reading is allowed to grow. Past it a line of
  /// text, a form field or a card stops reading as one thing.
  static const readableWidth = 640.0;

  /// The phone gutter, and the least a wider screen gets.
  static const gutter = 16.0;

  /// The width this page's content has.
  double get pageWidth =>
      dependOnInheritedWidgetOfExactType<_PageWidth>()?.width ??
      MediaQuery.sizeOf(this).width;

  /// Which of the three sizes this page is laid out at.
  LizmoWidth get pageSize => LizmoWidth.of(pageWidth);

  /// The side margin that keeps content in a readable column: 16 on a phone,
  /// and on a tablet whatever centres a column of [readableWidth].
  double get pageGutter =>
      math.max(gutter, (pageWidth - readableWidth) / 2);

  /// A page's padding, with the gutter at the sides.
  EdgeInsets pageInsets(double top, double bottom) =>
      EdgeInsets.fromLTRB(pageGutter, top, pageGutter, bottom);
}
