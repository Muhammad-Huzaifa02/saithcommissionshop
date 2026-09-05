// ── App Settings ───────────────────────────────────────────────────────────
class AppSettings {
  final double reorderPointKg;
  final double defaultGstPercent;
  final double defaultCommissionPercent;
  final double fixedCommissionPerBag;
  final bool   stockAlertsEnabled;
  final bool   paymentRemindersEnabled;
  final bool   automaticBackups;
  final String currency;
  final String timezone;
  final String businessCategory;

  const AppSettings({
    this.reorderPointKg          = 200,
    this.defaultGstPercent       = 0,
    this.defaultCommissionPercent = 2.0,
    this.fixedCommissionPerBag   = 0,
    this.stockAlertsEnabled      = true,
    this.paymentRemindersEnabled = true,
    this.automaticBackups        = true,
    this.currency                = 'PKR',
    this.timezone                = 'Asia/Karachi',
    this.businessCategory        = 'Commission Shop',
  });

  AppSettings copyWith({
    double? reorderPointKg,
    double? defaultGstPercent,
    double? defaultCommissionPercent,
    double? fixedCommissionPerBag,
    bool?   stockAlertsEnabled,
    bool?   paymentRemindersEnabled,
    bool?   automaticBackups,
    String? currency,
    String? timezone,
    String? businessCategory,
  }) => AppSettings(
    reorderPointKg:           reorderPointKg          ?? this.reorderPointKg,
    defaultGstPercent:        defaultGstPercent       ?? this.defaultGstPercent,
    defaultCommissionPercent: defaultCommissionPercent ?? this.defaultCommissionPercent,
    fixedCommissionPerBag:    fixedCommissionPerBag   ?? this.fixedCommissionPerBag,
    stockAlertsEnabled:       stockAlertsEnabled      ?? this.stockAlertsEnabled,
    paymentRemindersEnabled:  paymentRemindersEnabled ?? this.paymentRemindersEnabled,
    automaticBackups:         automaticBackups        ?? this.automaticBackups,
    currency:                 currency                ?? this.currency,
    timezone:                 timezone                ?? this.timezone,
    businessCategory:         businessCategory        ?? this.businessCategory,
  );
}
