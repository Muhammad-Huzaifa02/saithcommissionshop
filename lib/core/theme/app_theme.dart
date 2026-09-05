import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────
// COLORS  —  single source of truth
// ─────────────────────────────────────────────────────────────
class SColors {
  SColors._();

  // Brand greens - Unified Emerald Green
  static const Color primary      = Color(0xFF2ECC71);
  static const Color primaryLight = Color(0xFF2ECC71);
  static const Color primaryXLight= Color(0xFF2ECC71);
  static const Color primaryBg    = Color(0xFFEAF6EE); // Light emerald tint

  // Gold / amber
  static const Color gold         = Color(0xFFF39C12);
  static const Color goldLight    = Color(0xFFFFF3CD);

  // Semantic
  static const Color success      = Color(0xFF27AE60);
  static const Color successBg    = Color(0xFFEAF6EE);
  static const Color warning      = Color(0xFFF39C12);
  static const Color warningBg    = Color(0xFFFFF8E1);
  static const Color error        = Color(0xFFE74C3C);
  static const Color errorBg      = Color(0xFFFDEDEB);
  static const Color info         = Color(0xFF2980B9);
  static const Color infoBg       = Color(0xFFEBF5FB);

  // Neutrals — Premium Light Aesthetic
  static const Color background   = Color(0xFFF5F7FA);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color surfaceAlt   = Color(0xFFEDF1F5);
  static const Color border       = Color(0xFFD1D9E6);
  static const Color borderLight  = Color(0xFFE8ECEE);
  static const Color divider      = Color(0xFFE1E8F0);

  // 3D Glassmorphic additions
  static const Color deepDark     = Color(0xFF0F1419); // Rich slate/black
  static const Color glassWhite   = Color(0x26FFFFFF); // 15% white
  static const Color glassBorder  = Color(0x33FFFFFF); // 20% white

  // Text — light mode
  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF5A6472);
  static const Color textTertiary  = Color(0xFF9EA8B3);
  static const Color textOnDark    = Color(0xFFFFFFFF);
  static const Color textOnDarkSub = Color(0xB3FFFFFF); // 70% white

  // Dark mode surfaces
  static const Color darkBackground  = Color(0xFF0D1117);
  static const Color darkSurface     = Color(0xFF161B22);
  static const Color darkSurfaceAlt  = Color(0xFF1C2128);
  static const Color darkBorder      = Color(0xFF30363D);
  static const Color darkTextPrimary = Color(0xFFE6EDF3);
  static const Color darkTextSecondary= Color(0xFF8B949E);

  // Status chips
  static const Color paidBg        = Color(0xFFEAF6EE);
  static const Color paidText      = Color(0xFF27AE60);
  static const Color pendingBg     = Color(0xFFFFF8E1);
  static const Color pendingText   = Color(0xFFF39C12);
  static const Color overdueBg     = Color(0xFFFDEDEB);
  static const Color overdueText   = Color(0xFFE74C3C);

  // Category icon colors (for quick actions, menu items)
  static const Color catGreen      = Color(0xFF27AE60);
  static const Color catBlue       = Color(0xFF2980B9);
  static const Color catOrange     = Color(0xFFE67E22);
  static const Color catPurple     = Color(0xFF8E44AD);
  static const Color catTeal       = Color(0xFF16A085);
  static const Color catRed        = Color(0xFFE74C3C);
  static const Color catIndigo     = Color(0xFF2C3E50);
  static const Color catGold       = Color(0xFFF39C12);
}

// ─────────────────────────────────────────────────────────────
// SPACING  —  4-pt grid
// ─────────────────────────────────────────────────────────────
class SSpacing {
  SSpacing._();
  static const double xxs = 2;
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;

  // Named page padding
  static const EdgeInsets pagePadding     = EdgeInsets.all(md);
  static const EdgeInsets pageHorizontal  = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets cardPadding     = EdgeInsets.all(md);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm + xs);
}

// ─────────────────────────────────────────────────────────────
// BORDER RADIUS  —  unified scale
// ─────────────────────────────────────────────────────────────
class SRadius {
  SRadius._();
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 24;
  static const double full = 999;

  static const BorderRadius radiusXs   = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSm   = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd   = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg   = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl   = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(full));
}

// ─────────────────────────────────────────────────────────────
// SHADOWS  —  Neumorphic (3D)
// ─────────────────────────────────────────────────────────────
class SShadow {
  SShadow._();

  static List<BoxShadow> get card => neoOut;

  // Popped out look - Premium Light Soft Depth
  static List<BoxShadow> get neoOut => [
    BoxShadow(
      color: const Color(0xFFB8C2CC).withOpacity(0.4),
      offset: const Offset(6, 6),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Colors.white,
      offset: const Offset(-6, -6),
      blurRadius: 12,
    ),
  ];

  // Pressed in look - Soft Recess
  static List<BoxShadow> get neoIn => [
    BoxShadow(
      color: const Color(0xFFB8C2CC).withOpacity(0.3),
      offset: const Offset(2, 2),
      blurRadius: 4,
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.8),
      offset: const Offset(-2, -2),
      blurRadius: 4,
    ),
  ];

  // Global consistency
  static List<BoxShadow> get neoOutDark => neoOut;

  // Modal / bottom sheet
  static List<BoxShadow> get modal => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, -4),
    ),
  ];

  // Floating action / hero elements
  static List<BoxShadow> get floating => [
    BoxShadow(
      color: const Color(0xFF0F5C2E).withValues(alpha: 0.30),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  // No shadow
  static List<BoxShadow> get none => [];
}

// ─────────────────────────────────────────────────────────────
// GRADIENTS
// ─────────────────────────────────────────────────────────────
class SGradient {
  SGradient._();

  // Main brand gradient — app bars, hero sections, splash
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
  );

  // Lighter for cards / banners
  static const LinearGradient primarySoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEAF6EE), Color(0xFFD4EFDF)],
  );

  // Gold — for premium / VIP highlights
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
  );

  // Today summary strip
  static const LinearGradient todayStrip = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
  );

  // Subtle card tint (light mode)
  static const LinearGradient cardTint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F9F6)],
  );

  // Dark mode gradient
  static const LinearGradient darkPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF021A0B), Color(0xFF0A3D1F), Color(0xFF0F5C2E)],
  );

  // 3D Glassmorphic gradients
  static const LinearGradient glassHero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
  );

  static const LinearGradient accentGlass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x33FFFFFF), Color(0x0DFFFFFF)],
  );
}

// ─────────────────────────────────────────────────────────────
// TYPOGRAPHY  —  defined text style scale
// ─────────────────────────────────────────────────────────────
class SText {
  SText._();

  // Standard text colors for Light Mode
  static const _baseColor = Color(0xFF1A1A2E);
  static const _subColor  = Color(0xFF5A6472);

  // Display
  static const TextStyle displayLg = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.2, color: _baseColor,
  );
  static const TextStyle displayMd = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.25, color: _baseColor,
  );

  // Headings
  static const TextStyle headingXl = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.3, color: _baseColor,
  );
  static const TextStyle headingLg = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, height: 1.35, color: _baseColor,
  );
  static const TextStyle headingMd = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, height: 1.4, color: _baseColor,
  );
  static const TextStyle headingSm = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, height: 1.4, color: _baseColor,
  );

  // Body
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400, height: 1.6, color: _subColor,
  );
  static const TextStyle bodyMd = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.55, color: _subColor,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400, height: 1.5, color: _subColor,
  );
  static const TextStyle bodyXs = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, height: 1.5, color: _subColor,
  );

  // Labels & chips
  static const TextStyle labelLg = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: _baseColor,
  );
  static const TextStyle labelMd = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: _baseColor,
  );
  static const TextStyle labelSm = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.2, color: _baseColor,
  );
  static const TextStyle labelXs = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3, color: _baseColor,
  );

  // PKR Values
  static const TextStyle amountLg = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: _baseColor,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle amountMd = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: _baseColor,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle amountSm = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, color: _baseColor,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle amountXs = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600, color: _baseColor,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Section headers
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: SColors.textTertiary,
  );
}

// ─────────────────────────────────────────────────────────────
// SHARED WIDGET STYLES
// ─────────────────────────────────────────────────────────────
class SWidgetStyle {
  SWidgetStyle._();

  // Standard card decoration (3D Neumorphic)
  static BoxDecoration cardDecoration({
    BuildContext? context,
    Color? color,
    bool bordered = false,
    bool elevated = true,
  }) {
    final isDark = context != null && Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: color ?? (isDark ? SColors.darkSurface : SColors.surface),
      borderRadius: SRadius.radiusMd,
      border: bordered
          ? Border.all(color: isDark ? SColors.darkBorder : SColors.border, width: 0.5)
          : null,
      boxShadow: elevated ? (isDark ? SShadow.neoOutDark : SShadow.neoOut) : SShadow.none,
    );
  }

  // Icon container (3D well)
  static BoxDecoration iconBg(BuildContext context, Color color, {double radius = SRadius.sm}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? SColors.darkSurface : SColors.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: isDark ? SShadow.neoIn : SShadow.neoIn,
    );
  }

  // Status badge decoration (Embossed)
  static BoxDecoration statusBadge(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.15),
    borderRadius: SRadius.radiusFull,
    border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
  );

  // 3D Glass decoration
  static BoxDecoration glassDecoration({
    double blur = 10,
    double opacity = 0.1,
    double borderRadius = 24,
    Color? color,
  }) => BoxDecoration(
    color: (color ?? Colors.white).withOpacity(opacity),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
  );

  // Input decoration (Recessed 3D)
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? prefix,
    Widget? suffix,
    bool isDark = false,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefix,
    suffixIcon: suffix,
    filled: true,
    fillColor: isDark ? SColors.darkSurfaceAlt : SColors.surfaceAlt,
    contentPadding: const EdgeInsets.symmetric(
        horizontal: SSpacing.md, vertical: SSpacing.sm + SSpacing.xs),
    border: OutlineInputBorder(
        borderRadius: SRadius.radiusMd,
        borderSide: BorderSide(color: isDark ? SColors.darkBorder : SColors.border, width: 0.5)),
    enabledBorder: OutlineInputBorder(
        borderRadius: SRadius.radiusMd,
        borderSide: BorderSide(color: isDark ? SColors.darkBorder : SColors.border, width: 0.5)),
    focusedBorder: OutlineInputBorder(
        borderRadius: SRadius.radiusMd,
        borderSide: const BorderSide(color: SColors.primary, width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: SRadius.radiusMd,
        borderSide: const BorderSide(color: SColors.error, width: 1)),
    labelStyle: SText.labelLg.copyWith(color: SColors.textSecondary),
    hintStyle: SText.bodyMd.copyWith(color: SColors.textTertiary),
  );
}

// ─────────────────────────────────────────────────────────────
// STATUS HELPERS
// ─────────────────────────────────────────────────────────────
class SStatus {
  SStatus._();

  static Color bgColor(String status) => switch (status.toLowerCase()) {
    'paid'      => SColors.paidBg,
    'pending'   => SColors.pendingBg,
    'overdue'   => SColors.overdueBg,
    'partial'   => SColors.warningBg,
    'cancelled' => SColors.errorBg,
    _           => SColors.surfaceAlt,
  };

  static Color textColor(String status) => switch (status.toLowerCase()) {
    'paid'      => SColors.paidText,
    'pending'   => SColors.pendingText,
    'overdue'   => SColors.overdueText,
    'partial'   => SColors.warning,
    'cancelled' => SColors.error,
    _           => SColors.textSecondary,
  };

  static IconData icon(String status) => switch (status.toLowerCase()) {
    'paid'      => Icons.check_circle_outline,
    'pending'   => Icons.schedule_outlined,
    'overdue'   => Icons.warning_amber_outlined,
    'partial'   => Icons.pie_chart_outline,
    'cancelled' => Icons.cancel_outlined,
    _           => Icons.help_outline,
  };
}

// ─────────────────────────────────────────────────────────────
// MAIN THEME  —  AppTheme.lightTheme / AppTheme.darkTheme
// (Keep this class name — all existing imports still work)
// ─────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  // ── Keep these so existing `AppTheme.green` references compile ──
  static const Color green      = SColors.primary;
  static const Color darkGreen  = Color(0xFF063B1C);
  static const Color lightGreen = SColors.primaryXLight;
  static const Color gold       = SColors.gold;

  // Main Theme Configurations (Reverted to Premium Light)
  static ThemeData get lightTheme {
    const cs = ColorScheme(
      brightness:     Brightness.light,
      primary:        SColors.primary,
      onPrimary:      Colors.white,
      primaryContainer: Color(0xFFEDF1F5),
      onPrimaryContainer: SColors.primary,
      secondary:      SColors.gold,
      onSecondary:    Colors.white,
      secondaryContainer: Color(0xFFFFF3CD),
      onSecondaryContainer: SColors.gold,
      error:          SColors.error,
      onError:        Colors.white,
      errorContainer: SColors.errorBg,
      onErrorContainer: SColors.error,
      surface:        SColors.surface,
      onSurface:      SColors.textPrimary,
      surfaceContainerHighest: SColors.surfaceAlt,
      outline:        SColors.border,
      outlineVariant: SColors.borderLight,
    );

    return ThemeData(
      useMaterial3:      true,
      colorScheme:       cs,
      scaffoldBackgroundColor: SColors.background,
      fontFamily:        'Roboto',

      appBarTheme: AppBarTheme(
        backgroundColor:      SColors.primary,
        foregroundColor:      Colors.white,
        elevation:            0,
        scrolledUnderElevation: 0,
        systemOverlayStyle:   SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        titleTextStyle: SText.headingMd.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
      ),

      cardTheme: CardThemeData(
        elevation:  0,
        color:      SColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: SRadius.radiusMd,
          side: const BorderSide(color: SColors.border, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:  SColors.primary,
          foregroundColor:  Colors.white,
          elevation:        4,
          shadowColor:      const Color(0xFFB8C2CC).withOpacity(0.5),
          padding: const EdgeInsets.symmetric(
              horizontal: SSpacing.lg, vertical: SSpacing.md),
          minimumSize: const Size(88, 50),
          shape: RoundedRectangleBorder(borderRadius: SRadius.radiusMd),
          textStyle: SText.labelLg.copyWith(fontWeight: FontWeight.bold),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SColors.primary,
          side: const BorderSide(color: SColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
              horizontal: SSpacing.lg, vertical: SSpacing.md),
          minimumSize: const Size(88, 50),
          shape: RoundedRectangleBorder(borderRadius: SRadius.radiusMd),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:        true,
        fillColor:     SColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: SSpacing.md, vertical: SSpacing.md - SSpacing.xs),
        border: OutlineInputBorder(
            borderRadius: SRadius.radiusMd,
            borderSide: const BorderSide(color: SColors.border, width: 0.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: SRadius.radiusMd,
            borderSide: const BorderSide(color: SColors.border, width: 0.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: SRadius.radiusMd,
            borderSide: const BorderSide(color: SColors.primary, width: 1.5)),
        labelStyle: SText.labelLg.copyWith(color: SColors.textSecondary),
        hintStyle:  SText.bodyMd.copyWith(color: SColors.textSecondary),
        prefixIconColor: SColors.textSecondary,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:  SColors.surface,
        indicatorColor:   const Color(0xFFEAF6EE),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return SText.labelSm.copyWith(
                color: SColors.primary, fontWeight: FontWeight.w700);
          }
          return SText.labelSm.copyWith(color: SColors.textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: SColors.primary, size: 22);
          }
          return const IconThemeData(color: SColors.textSecondary, size: 22);
        }),
        height: 68,
      ),

      dividerTheme: const DividerThemeData(
        color: SColors.divider, thickness: 0.5, space: 0),

      tabBarTheme: TabBarThemeData(
        labelColor:           SColors.primary,
        unselectedLabelColor: SColors.textSecondary,
        indicatorColor:       SColors.primary,
        indicatorSize:        TabBarIndicatorSize.label,
        dividerColor:         Colors.transparent,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}

// ─────────────────────────────────────────────────────────────
// SHARED UI COMPONENTS  —  built on the tokens above
// Drop these anywhere in the app for consistency
// ─────────────────────────────────────────────────────────────

/// Standard icon container with 3D depth
class SIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const SIconBox({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: SWidgetStyle.iconBg(context, color, radius: SRadius.sm),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// Status badge chip  (Paid / Pending / Overdue)
class SStatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const SStatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final text = label ?? status;
    final fg   = SStatus.textColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: SSpacing.sm, vertical: SSpacing.xxs + 1),
      decoration: SWidgetStyle.statusBadge(fg),
      child: Text(
        text,
        style: SText.labelXs.copyWith(color: fg),
      ),
    );
  }
}

/// Section header with optional trailing widget
class SSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(0, SSpacing.lg, 0, SSpacing.sm),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(title.toUpperCase(), style: SText.sectionHeader),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Gradient app bar header (for dashboard hero sections)
class SGradientHeader extends StatelessWidget {
  final Widget child;
  final double height;
  final LinearGradient? gradient;

  const SGradientHeader({
    super.key,
    required this.child,
    this.height = 160,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient ?? SGradient.primary,
      ),
      child: SafeArea(child: child),
    );
  }
}

/// Standard 3D card wrapper
class SCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool elevated;

  const SCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: padding ?? SSpacing.cardPadding,
        decoration: BoxDecoration(
          color: color ?? (isDark ? SColors.darkSurface : SColors.surface),
          borderRadius: SRadius.radiusMd,
          boxShadow: elevated 
              ? (isDark ? SShadow.neoOutDark : SShadow.neoOut)
              : SShadow.none,
        ),
        child: child,
      ),
    );
  }
}

/// PKR amount formatter helper
class SPkr {
  SPkr._();
  static String format(double v) {
    if (v >= 10000000) return 'PKR ${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000)   return 'PKR ${(v / 100000).toStringAsFixed(1)} L';
    if (v >= 1000)     return 'PKR ${(v / 1000).toStringAsFixed(1)} K';
    return 'PKR ${v.toStringAsFixed(0)}';
  }

  static String compact(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000)   return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)     return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
