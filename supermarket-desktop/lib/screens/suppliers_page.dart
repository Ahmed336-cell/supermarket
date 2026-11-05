import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key, required this.api, required this.isAdmin});

  final ApiClient api;
  final bool isAdmin;

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  bool _loading = true;
  String? _error;
  List<Supplier> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.api.suppliers();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _edit({Supplier? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _SupplierDialog(api: widget.api, existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Supplier supplier) async {
    final ok = await confirm(
      context,
      title: 'Delete supplier',
      message: 'Delete ${supplier.name}?',
    );
    if (!ok || !mounted) return;
    try {
      await widget.api.deleteSupplier(supplier.id);
      if (!mounted) return;
      toast(context, 'Supplier deleted');
      await _load();
    } catch (error) {
      if (!mounted) return;
      toast(context, error.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Suppliers',
      subtitle: _loading ? 'Loading' : '${_items.length} suppliers',
      actions: [
        if (widget.isAdmin)
          FilledButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New supplier'),
          ),
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorRetry(message: _error!, onRetry: _load)
          : Panel(
              padding: EdgeInsets.zero,
              child: _items.isEmpty
                  ? const EmptyHint(message: 'No suppliers yet.')
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final supplier = _items[index];
                        final details = [
                          supplier.email,
                          supplier.phone,
                          supplier.address,
                        ].where((part) => part.isNotEmpty).join(' · ');
                        return ListTile(
                          title: Text(supplier.name),
                          subtitle: details.isEmpty ? null : Text(details),
                          trailing: widget.isAdmin
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      onPressed: () => _edit(existing: supplier),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () => _delete(supplier),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
            ),
    );
  }
}

class _SupplierDialog extends StatefulWidget {
  const _SupplierDialog({required this.api, this.existing});

  final ApiClient api;
  final Supplier? existing;

  @override
  State<_SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends State<_SupplierDialog> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _email = TextEditingController(text: widget.existing?.email ?? '');
    _phone = TextEditingController(text: widget.existing?.phone ?? '');
    _address = TextEditingController(text: widget.existing?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = {
      'name': name,
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'address': _address.text.trim(),
    };
    try {
      if (widget.existing == null) {
        await widget.api.createSupplier(body);
      } else {
        await widget.api.updateSupplier(widget.existing!.id, body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New supplier' : 'Edit supplier'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
