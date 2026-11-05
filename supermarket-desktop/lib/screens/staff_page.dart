import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme.dart';
import '../widgets/common.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'cashier';
  bool _saving = false;
  String? _error;
  String? _created;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (name.isEmpty || !email.contains('@') || password.length < 8) {
      setState(() {
        _error = 'Name, a valid email, and a password of 8+ characters.';
        _created = null;
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _created = null;
    });
    try {
      final user = await widget.api.register(
        name: name,
        email: email,
        password: password,
        role: _role,
      );
      if (!mounted) return;
      _name.clear();
      _email.clear();
      _password.clear();
      setState(() {
        _saving = false;
        _created = '${user.name} can sign in as ${user.role}.';
      });
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
    return PageFrame(
      title: 'Staff',
      subtitle: 'Register keeps you signed in. The API has no staff list.',
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Panel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 12),
                AppDropdown<String>(
                  value: _role,
                  items: const [
                    DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _role = value);
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ],
                if (_created != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _created!,
                    style: const TextStyle(color: AppColors.leaf),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Creating…' : 'Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
