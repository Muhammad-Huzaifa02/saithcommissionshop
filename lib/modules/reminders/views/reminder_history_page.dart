import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/modules/reminders/providers/reminder_provider.dart';
import 'package:saithcommissionshop/core/utils/app_utils.dart';

class ReminderHistoryPage extends StatelessWidget {
  const ReminderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReminderProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Reminder History"),
        actions: [
          if (rp.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context),
              tooltip: "Clear History",
            ),
        ],
      ),
      body: rp.history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: SColors.textTertiary),
                  const SizedBox(height: 16),
                  const Text("No reminders sent yet", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rp.history.length,
              itemBuilder: (_, i) {
                final r = rp.history[rp.history.length - 1 - i]; // Show newest first
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: SColors.success,
                      child: Icon(Icons.message, color: Colors.white, size: 20),
                    ),
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${r.phone}\n${PakistanFormatter.formatDate(r.time)}"),
                    trailing: Text(
                      "PKR ${r.amount.toStringAsFixed(0)}",
                      style: TextStyle(color: SColors.error, fontWeight: FontWeight.bold),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear History"),
        content: const Text("Delete all reminder history?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              context.read<ReminderProvider>().clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: SColors.error),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }
}

