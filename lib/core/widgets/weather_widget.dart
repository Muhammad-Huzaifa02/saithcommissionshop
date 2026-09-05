// ============================================================
// weather_widget.dart  —  Saith Commission Shop
// Real-time weather widget for Admin + Customer dashboards
//
// Components exported:
//   WeatherWidget  — full card (use in dashboard body)
//   WeatherChip    — compact pill (use in app bar)
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/home/providers/weather_provider.dart';
import 'package:saithcommissionshop/data/services/weather_service.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';

// ═════════════════════════════════════════════════════════════
// MAIN WEATHER CARD
// ═════════════════════════════════════════════════════════════
class WeatherWidget extends StatefulWidget {
  final bool showTip;
  const WeatherWidget({super.key, this.showTip = true});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _refreshCtrl;

  @override
  void initState() {
    super.initState();
    _refreshCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().fetch();
    });
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    super.dispose();
  }

  void _doRefresh() {
    _refreshCtrl.forward(from: 0);
    context.read<WeatherProvider>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<WeatherProvider>();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: switch (prov.state) {
        WeatherState.idle || WeatherState.loading =>
            const _WeatherSkeleton(key: ValueKey('skeleton')),
        WeatherState.error =>
            _WeatherError(
              key:        const ValueKey('error'),
              prov:       prov,
              onRetry:    _doRefresh,
            ),
        WeatherState.loaded =>
            _WeatherCard(
              key:        const ValueKey('loaded'),
              data:       prov.data!,
              showTip:    widget.showTip,
              warning:    prov.locationWarning,
              isBlocked:  prov.locationBlocked,
              isGpsOff:   prov.gpsOff,
              refreshCtrl: _refreshCtrl,
              onRefresh:   _doRefresh,
              onFixLocation: () => prov.locationBlocked
                  ? prov.openAppSettings()
                  : prov.openLocationSettings(),
              prov: prov,
            ),
      },
    );
  }
}

// ── Full weather card ─────────────────────────────────────────
class _WeatherCard extends StatelessWidget {
  final WeatherData        data;
  final bool               showTip;
  final String?            warning;
  final bool               isBlocked;
  final bool               isGpsOff;
  final AnimationController refreshCtrl;
  final VoidCallback       onRefresh;
  final VoidCallback       onFixLocation;
  final WeatherProvider    prov;

  const _WeatherCard({
    super.key,
    required this.data,
    required this.showTip,
    required this.warning,
    required this.isBlocked,
    required this.isGpsOff,
    required this.refreshCtrl,
    required this.onRefresh,
    required this.onFixLocation,
    required this.prov,
  });

  // Sky gradient based on time of day + weather
  LinearGradient get _skyGradient {
    if (!data.isDaytime) {
      return const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF0D1B2A), Color(0xFF1B2B44)],
      );
    }
    if (data.isRaining) {
      return const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF37474F), Color(0xFF546E7A)],
      );
    }
    if (data.weatherCode == 3) { // overcast
      return const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF455A64), Color(0xFF607D8B)],
      );
    }
    if (data.weatherCode <= 2) { // clear/mostly clear
      return const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
    );
  }

  Color get _detailBg {
    if (!data.isDaytime) return const Color(0xFF162032);
    if (data.isRaining)  return const Color(0xFF2E3F47);
    return const Color(0xFF1565C0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: SRadius.radiusMd,
        border: Border.all(color: SColors.border, width: 0.5),
        boxShadow: SShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Main section ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(SSpacing.md),
            decoration: BoxDecoration(gradient: _skyGradient),
            child: Column(children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Big weather emoji
                  Text(data.iconEmoji,
                      style: const TextStyle(fontSize: 52, height: 1)),

                  const SizedBox(width: SSpacing.md),

                  // Temperature + description
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Temp
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(data.tempCStr,
                              style: SText.displayMd.copyWith(
                                color: Colors.white,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              )),
                          const SizedBox(width: SSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(data.description,
                                style: SText.bodyMd.copyWith(
                                    color: Colors.white70)),
                          ),
                        ],
                      ),

                      const SizedBox(height: SSpacing.xs),

                      // City + live badge
                      Row(children: [
                        Icon(
                          data.isFallback
                              ? Icons.location_off_outlined
                              : Icons.location_on_outlined,
                          color: Colors.white60, size: 13,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            data.city,
                            style: SText.labelMd.copyWith(
                                color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: SSpacing.sm),
                        // Live dot
                        if (!data.isFallback) ...[
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF69F0AE),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text('LIVE',
                              style: SText.labelXs.copyWith(
                                  color: Color(0xFF69F0AE))),
                        ],
                      ]),
                    ],
                  )),

                  // Refresh button
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 1.0)
                        .animate(refreshCtrl),
                    child: GestureDetector(
                      onTap: onRefresh,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: SRadius.radiusSm,
                        ),
                        child: const Icon(Icons.refresh,
                            color: Colors.white70, size: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: SSpacing.sm),
              Text(
                'Updated ${data.lastUpdatedStr}',
                style: SText.labelXs.copyWith(
                    color: Colors.white38),
              ),
            ]),
          ),

          // ── Detail strip ─────────────────────────────────
          Container(
            color: _detailBg,
            padding: const EdgeInsets.symmetric(
                vertical: SSpacing.md - SSpacing.xs,
                horizontal: SSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DetailItem(
                  icon: Icons.thermostat_outlined,
                  label: 'Feels like',
                  value: data.feelsLikeStr,
                ),
                _Vline(),
                _DetailItem(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidity',
                  value: data.humidityStr,
                ),
                _Vline(),
                _DetailItem(
                  icon: Icons.air_outlined,
                  label: 'Wind',
                  value: data.windStr,
                ),
                _Vline(),
                _DetailItem(
                  icon: Icons.wb_sunny_outlined,
                  label: 'UV Index',
                  value: data.uvStr,
                ),
              ],
            ),
          ),

          // ── Business tip ──────────────────────────────────
          if (showTip)
            Container(
              color: SColors.surface,
              padding: const EdgeInsets.symmetric(
                  horizontal: SSpacing.md,
                  vertical: SSpacing.sm + SSpacing.xs),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: data.isRaining
                          ? SColors.warningBg
                          : SColors.primaryBg,
                      borderRadius: SRadius.radiusSm,
                    ),
                    child: Icon(
                      data.isRaining
                          ? Icons.umbrella_outlined
                          : Icons.storefront_outlined,
                      color: data.isRaining
                          ? SColors.warning
                          : SColors.primary,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: SSpacing.sm),
                  Expanded(
                    child: Text(
                      data.businessTip,
                      style: SText.bodyXs.copyWith(
                          color: SColors.textSecondary,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

          // ── Location warning banner ───────────────────────
          if (warning != null)
            Container(
              color: SColors.warningBg,
              padding: const EdgeInsets.symmetric(
                  horizontal: SSpacing.md,
                  vertical: SSpacing.sm),
              child: Row(children: [
                Icon(Icons.location_off_outlined,
                    color: SColors.warning, size: 14),
                const SizedBox(width: SSpacing.xs),
                Expanded(
                  child: Text(warning!,
                      style: SText.labelXs.copyWith(
                          color: SColors.warning)),
                ),
                if (isBlocked || isGpsOff)
                  GestureDetector(
                    onTap: onFixLocation,
                    child: Text(
                      isBlocked ? 'Open Settings' : 'Enable GPS',
                      style: SText.labelXs.copyWith(
                          color: SColors.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ]),
            ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _DetailItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.white54, size: 14),
      const SizedBox(height: 3),
      Text(value,
          style: SText.labelMd.copyWith(
              color: Colors.white, fontWeight: FontWeight.w700)),
      Text(label,
          style: SText.labelXs.copyWith(color: Colors.white54)),
    ],
  );
}

class _Vline extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 0.5, height: 32,
      color: Colors.white.withValues(alpha: 0.18));
}

// ═════════════════════════════════════════════════════════════
// LOADING SKELETON
// ═════════════════════════════════════════════════════════════
class _WeatherSkeleton extends StatefulWidget {
  const _WeatherSkeleton({super.key});
  @override
  State<_WeatherSkeleton> createState() => _WeatherSkeletonState();
}

class _WeatherSkeletonState extends State<_WeatherSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 0.85).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _shimmer(double w, double h) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: _anim.value),
        borderRadius: SRadius.radiusSm,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: SRadius.radiusMd,
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
        ),
        boxShadow: SShadow.card,
      ),
      padding: const EdgeInsets.all(SSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _shimmer(52, 52),
            const SizedBox(width: SSpacing.md),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _shimmer(90, 36),
              const SizedBox(height: SSpacing.sm),
              _shimmer(130, 14),
              const SizedBox(height: SSpacing.xs),
              _shimmer(80, 12),
            ]),
          ]),
          const SizedBox(height: SSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (_) => _shimmer(52, 40)),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ERROR STATE
// ═════════════════════════════════════════════════════════════
class _WeatherError extends StatelessWidget {
  final WeatherProvider prov;
  final VoidCallback    onRetry;
  const _WeatherError(
      {super.key, required this.prov, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isBlocked = prov.locationBlocked;
    final isGpsOff  = prov.gpsOff;

    return Container(
      padding: const EdgeInsets.all(SSpacing.md),
      decoration: BoxDecoration(
        color: SColors.surfaceAlt,
        borderRadius: SRadius.radiusMd,
        border: Border.all(color: SColors.border, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: SColors.warningBg,
            borderRadius: SRadius.radiusMd,
          ),
          child: const Icon(Icons.cloud_off_outlined,
              color: SColors.warning, size: 22),
        ),
        const SizedBox(width: SSpacing.md),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBlocked ? 'Location access blocked'
                  : isGpsOff ? 'GPS is turned off'
                  : 'Weather unavailable',
              style: SText.headingSm.copyWith(
                  color: SColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              isBlocked
                  ? 'Enable in Settings → Saith App → Location'
                  : isGpsOff
                      ? 'Turn on device GPS to get local weather'
                      : 'Check internet connection and try again',
              style: SText.bodyXs.copyWith(
                  color: SColors.textSecondary),
            ),
          ],
        )),
        const SizedBox(width: SSpacing.sm),
        Column(children: [
          if (isBlocked || isGpsOff)
            TextButton(
              onPressed: isBlocked
                  ? prov.openAppSettings
                  : prov.openLocationSettings,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: SSpacing.sm, vertical: 4)),
              child: Text(
                isBlocked ? 'Settings' : 'Enable',
                style: SText.labelSm.copyWith(
                    color: SColors.primary),
              ),
            ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: SSpacing.sm, vertical: 4)),
            child: Text('Retry',
                style: SText.labelSm.copyWith(
                    color: SColors.textSecondary)),
          ),
        ]),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// COMPACT CHIP  (for app bar)
// ═════════════════════════════════════════════════════════════
class WeatherChip extends StatefulWidget {
  const WeatherChip({super.key});
  @override
  State<WeatherChip> createState() => _WeatherChipState();
}

class _WeatherChipState extends State<WeatherChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(_pulseCtrl);
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<WeatherProvider>();

    if (prov.isLoading) {
      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, __) => Opacity(
          opacity: _pulseAnim.value,
          child: Container(
            width: 90, height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: SRadius.radiusFull,
            ),
          ),
        ),
      );
    }

    if (!prov.hasData) {
      if (prov.gpsOff) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: SSpacing.sm, vertical: SSpacing.xs),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: SRadius.radiusFull,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.location_off_outlined, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text('GPS Off', style: SText.labelXs.copyWith(color: Colors.white70)),
          ]),
        );
      }
      return const SizedBox.shrink();
    }

    final w = prov.data!;

    return GestureDetector(
      onTap: () => prov.refresh(),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: SSpacing.sm + SSpacing.xs,
            vertical: SSpacing.xs),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: SRadius.radiusFull,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(w.iconEmoji,
              style: const TextStyle(fontSize: 14)),
          const SizedBox(width: SSpacing.xs),
          Text(
            w.tempCStr,
            style: SText.labelMd.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: SSpacing.xs),

          // Live / fallback indicator
          if (!w.isFallback) ...[
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(
                      105, 240, 174, _pulseAnim.value),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 3),
          ],

          Flexible(
            child: Text(
              w.isFallback ? 'Lahore' : w.city,
              style: SText.labelXs.copyWith(
                  color: Colors.white70),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ]),
      ),
    );
  }
}
