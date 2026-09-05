import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saithcommissionshop/modules/suppliers/providers/supplier_provider.dart';
import 'package:saithcommissionshop/data/models/supplier_model.dart';
import 'package:saithcommissionshop/core/theme/app_theme.dart';
import 'package:saithcommissionshop/core/utils/overflow_handler.dart';

class AdminSuppliersPage extends StatefulWidget {
  const AdminSuppliersPage({super.key});
  @override
  State<AdminSuppliersPage> createState() => _AdminSuppliersPageState();
}

class _AdminSuppliersPageState extends State<AdminSuppliersPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SupplierProvider>();
    final filtered = sp.suppliers.where((s) => s.name.toLowerCase().contains(_search.toLowerCase()) || s.phone.contains(_search)).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Suppliers'),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_alt), onPressed: () => _showAddSupplierDialog(context))
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search suppliers...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(borderRadius: SRadius.radiusMd),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No suppliers found'))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final s = filtered[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(s.name[0])),
                  title: ResponsiveText(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(s.phone),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showSupplierDetails(context, s),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final ntnCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Supplier'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
            TextField(controller: ntnCtrl, decoration: const InputDecoration(labelText: 'NTN')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            context.read<SupplierProvider>().addSupplier(Supplier(
              id: '',
              name: nameCtrl.text,
              phone: phoneCtrl.text,
              address: addrCtrl.text,
              ntn: ntnCtrl.text,
              createdAt: DateTime.now(),
            ));
            Navigator.pop(ctx);
          }, child: const Text('Add')),
        ],
      ),
    );
  }

  void _showSupplierDetails(BuildContext context, Supplier s) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Phone: ${s.phone}'),
            Text('Address: ${s.address}'),
            if (s.ntn != null) Text('NTN: ${s.ntn}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
