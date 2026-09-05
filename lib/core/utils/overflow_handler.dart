import 'package:flutter/material.dart';

/// =====================
/// RESPONSIVE SCROLL HANDLER
/// =====================
class ResponsiveOverflowHandler extends StatelessWidget {
  final Widget child;
  final bool useScrollbar;
  final ScrollController? controller;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;

  const ResponsiveOverflowHandler({
    super.key,
    required this.child,
    this.useScrollbar = false,
    this.controller,
    this.padding = EdgeInsets.zero,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final scrollController = controller ?? ScrollController();

    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: padding,
          physics: physics ?? const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );

    if (useScrollbar) {
      content = Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: content,
      );
    }

    return content;
  }
}

/// =====================
/// RESPONSIVE TEXT
/// =====================
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextOverflow overflow;

  const ResponsiveText(
      this.text, {
        super.key,
        this.style,
        this.maxLines = 1,
        this.textAlign,
        this.overflow = TextOverflow.ellipsis,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
    );
  }
}

/// =====================
/// ADAPTIVE LAYOUT
/// =====================
class AdaptiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)
  builder;

  const AdaptiveLayout({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: builder);
  }
}

/// =====================
/// SAFE ROW (WRAP)
/// =====================
class SafeRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  const SafeRow({
    super.key,
    required this.children,
    this.spacing = 8,
    this.runSpacing = 4,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: children,
    );
  }
}

/// =====================
/// PAGE SCAFFOLD
/// =====================
class AppPageScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool scrollable;

  const AppPageScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final content =
    scrollable ? ResponsiveOverflowHandler(child: body) : body;

    return Scaffold(
      appBar:
      title != null ? AppBar(automaticallyImplyLeading: false, title: Text(title!), actions: actions) : null,
      body: SafeArea(child: content),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// =====================
/// RESPONSIVE SPACING
/// =====================
class ResponsiveSpacing extends StatelessWidget {
  final double smallScreen;
  final double largeScreen;
  final Axis axis;

  const ResponsiveSpacing({
    super.key,
    this.smallScreen = 8,
    this.largeScreen = 24,
    this.axis = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final size = width < 600 ? smallScreen : largeScreen;

    return axis == Axis.vertical
        ? SizedBox(height: size)
        : SizedBox(width: size);
  }
}

/// =====================
/// RESPONSIVE GRID
/// =====================
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int phoneColumns;
  final int tabletColumns;
  final int desktopColumns;
  final bool scrollable;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.phoneColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final crossAxisCount = width < 600
        ? phoneColumns
        : width < 1200
        ? tabletColumns
        : desktopColumns;

    return GridView.builder(
      shrinkWrap: !scrollable,
      physics:
      scrollable ? null : const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
      ),
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
    );
  }
}

/// =====================
/// RESPONSIVE LAYOUT
/// =====================
class ResponsiveLayout extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;
  final bool isMobile;

  const ResponsiveLayout({
    super.key,
    required this.children,
    this.breakpoint = 600,
    this.isMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final useColumn = isMobile ? width < breakpoint : width >= breakpoint;

    return useColumn
        ? Column(children: children)
        : Row(children: children);
  }
}

/// =====================
/// SAFE PADDING
/// =====================
class SafePadding extends StatelessWidget {
  final Widget child;
  final bool scrollable;

  const SafePadding({
    super.key,
    required this.child,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = scrollable
        ? SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: child,
    )
        : child;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }
}

/// =====================
/// BUILD CONTEXT EXTENSIONS
/// =====================
extension ResponsiveValueExtension on BuildContext {
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(this).size.width;
    if (width >= 1200 && desktop != null) return desktop;
    if (width >= 600 && tablet != null) return tablet;
    return mobile;
  }

  ScreenSize get screenSize {
    final width = MediaQuery.of(this).size.width;
    if (width >= 1200) return ScreenSize.desktop;
    if (width >= 600) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }
}

enum ScreenSize { mobile, tablet, desktop }

/// =====================
/// WIDGET EXTENSIONS
/// =====================
extension OverflowExtension on Widget {
  Widget get scrollable => ResponsiveOverflowHandler(child: this);

  Widget padded(double value) =>
      Padding(padding: EdgeInsets.all(value), child: this);

  Widget centered({double? maxWidth}) => Center(
    child: maxWidth != null
        ? ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: this,
          )
        : this,
  );

  Widget withLoading(bool isLoading) => Stack(
    children: [
      AbsorbPointer(absorbing: isLoading, child: this),
      if (isLoading)
        const Center(child: CircularProgressIndicator()),
    ],
  );
}

/// =====================
/// CUSTOM LOADER
/// =====================
class CustomLoader extends StatelessWidget {
  final Color? color;
  final double size;

  const CustomLoader({super.key, this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(
          color: color ?? Theme.of(context).primaryColor,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

/// =====================
/// EMPTY STATE
/// =====================
class EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const EmptyState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

/// =====================
/// ERROR STATE
/// =====================
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
