import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme.dart';

class OwnerLoginScreen extends StatefulWidget {
  final ApiService api;
  final void Function(String token, AppUser user) onAuthenticated;

  const OwnerLoginScreen({super.key, required this.api, required this.onAuthenticated});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final _emailCtrl = TextEditingController(text: 'owner@ghazi.ye');
  final _passCtrl = TextEditingController(text: 'owner123');
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.api.login(_emailCtrl.text.trim(), _passCtrl.text);
      final user = AppUser.fromJson(data['user']);
      if (user.role != 'owner') {
        setState(() => _error = 'هذا الحساب ليس حساب صاحب محطة');
        return;
      }
      widget.onAuthenticated(data['token'], user);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.dashboard_customize_rounded,
                      size: 48, color: AppColors.primaryDeepNavy),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text('غازي',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDeepNavy)),
                  ),
                  const Center(
                    child: Text('لوحة تحكم صاحب المحطة',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passCtrl,
                    decoration: const InputDecoration(labelText: 'كلمة المرور'),
                    obscureText: true,
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.danger)),
                  ],
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('دخول'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
