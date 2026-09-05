import 'package:flutter/material.dart';

/// A utility widget to handle common layout constraints and prevent overflow.
class LayoutGuard extends StatelessWidget {
  final Widget child;
  final double? maxHeight;
  final bool scrollable;

  const LayoutGuard({
    super.key,
    required this.child,
    this.maxHeight,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (maxHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: content,
      );
    }

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    return content;
  }

  /// Wraps a widget (like a chart) that requires bounded height.
  static Widget bounded({
    required Widget child,
    double height = 200,
  }) {
    return SizedBox(
      height: height,
      child: child,
    );
  }

  /// Ensures Row children don't overflow by wrapping them in Expanded if necessary.
  static Widget rowSafe(List<Widget> children, {
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children.map((widget) {
        if (widget is Expanded || widget is Flexible || widget is Spacer) {
          return widget;
        }
        return Flexible(child: widget);
      }).toList(),
    );
  }
}
