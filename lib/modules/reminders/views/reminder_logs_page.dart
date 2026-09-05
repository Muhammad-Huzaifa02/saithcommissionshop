import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/reminders/providers/reminder_log_provider.dart';
import 'package:saithcommissionshop/data/models/reminder_log_model.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/core/utils/overflow_handler.dart';

class ReminderLogsPage extends StatefulWidget {
  const ReminderLogsPage({super.key});
  @override
  State<ReminderLogsPage> createState() => _ReminderLogsPageState();
}

class _ReminderLogsPageState extends State<ReminderLogsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderLogProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ReminderLogProvider>();

    return Scaffold(
      backgroundColor: SColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Reminder Logs',
              style: SText.headingMd.copyWith(color: Colors.white)),
          Text('Payment follow-ups',
              style: SText.bodyXs.copyWith(color: SColors.textOnDarkSub)),
        ]),
      ),
      body: Column(children: [
        // Summary strip
        Container(
          decoration: const BoxDecoration(gradient: SGradient.primarySoft),
          padding: const EdgeInsets.symmetric(vertical: SSpacing.md),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ReminderStat('Total Sent',   '${prov.logs.length}', Colors.white),
              _vDiv(),
              _ReminderStat('Total Amount', SPkr.compact(prov.totalReminded), SColors.gold),
              _vDiv(),
              _ReminderStat('Paid After',   '${prov.paidCount}', SColors.primaryXLight),
            ],
          ),
        ),

        // Log list
        Expanded(
          child: prov.isLoading
              ? const Center(child: CircularProgressIndicator(
                  color: SColors.primary, strokeWidth: 2))
              : prov.logs.isEmpty
                  ? const Center(child: EmptyState(message: 'No reminders logged yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(SSpacing.md),
                      itemCount: prov.logs.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: SSpacing.sm),
                        child: _ReminderLogTile(
                          log: prov.logs[i],
                          onMarkPaid: () =>
                              prov.updateStatus(prov.logs[i].id, 'paid'),
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _vDiv() => Container(width: 0.5, height: 32,
      color: Colors.white.withValues(alpha: 0.3));
}

class _ReminderStat extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _ReminderStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: SText.amountSm.copyWith(color: color)),
    const SizedBox(height: 2),
    Text(label, style: SText.labelXs.copyWith(color: SColors.textOnDarkSub)),
  ]);
}

class _ReminderLogTile extends StatelessWidget {
  final ReminderLog  log;
  final VoidCallback onMarkPaid;
  const _ReminderLogTile({required this.log, required this.onMarkPaid});

  @override
  Widget build(BuildContext context) {
    final isPaid = log.status == 'paid';
    final channelIcon = switch (log.channel) {
      'whatsapp' => Icons.chat_bubble_outline,
      'sms'      => Icons.sms_outlined,
      _          => Icons.phone_outlined,
    };
    final channelColor = switch (log.channel) {
      'whatsapp' => const Color(0xFF25D366),
      'sms'      => SColors.catBlue,
      _          => SColors.catOrange,
    };

    return Container(
      padding: SSpacing.cardPadding,
      decoration: BoxDecoration(
        color: SColors.surface,
        borderRadius: SRadius.radiusMd,
        border: Border.all(color: SColors.border, width: 0.5),
        boxShadow: SShadow.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: channelColor.withValues(alpha: 0.12),
              borderRadius: SRadius.radiusMd,
            ),
            child: Icon(channelIcon, color: channelColor, size: 20),
          ),
          const SizedBox(width: SSpacing.md),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log.customerName,
                  style: SText.headingSm.copyWith(
                      color: SColors.textPrimary)),
              Text(log.customerPhone,
                  style: SText.bodyXs.copyWith(
                      color: SColors.textSecondary)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(SPkr.format(log.pendingAmount),
                style: SText.amountXs.copyWith(
                    color: SColors.error)),
            const SizedBox(height: 4),
            SStatusBadge(
              status: isPaid ? 'paid' : 'pending',
              label: isPaid ? 'Paid ✓' : 'Pending',
            ),
          ]),
        ]),

        const SizedBox(height: SSpacing.sm),
        const Divider(height: 0.5, color: SColors.divider),
        const SizedBox(height: SSpacing.sm),

        Text(log.message,
            style: SText.bodyXs.copyWith(
                color: SColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),

        const SizedBox(height: SSpacing.sm),
        Row(children: [
          Text(
            '${log.sentAt.day}/${log.sentAt.month}/${log.sentAt.year} '
            '· by ${log.sentBy}',
            style: SText.labelXs.copyWith(color: SColors.textTertiary),
          ),
          const Spacer(),
          if (!isPaid)
            GestureDetector(
              onTap: onMarkPaid,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: SSpacing.md, vertical: SSpacing.xs),
                decoration: BoxDecoration(
                  color: SColors.primaryBg,
                  borderRadius: SRadius.radiusFull,
                ),
                child: Text('Mark Paid',
                    style: SText.labelXs.copyWith(
                        color: SColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      ]),
    );
  }
}
