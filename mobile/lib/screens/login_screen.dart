import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onNavigateToSignup;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    Key? key,
    required this.onNavigateToSignup,
    required this.onLoginSuccess,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال البريد الإلكتروني وكلمة المرور'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.instance.login(email, password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الدخول بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onLoginSuccess();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'حدث خطأ أثناء تسجيل الدخول';
      if (e.code == 'user-not-found') {
        errorMessage = 'لا يوجد حساب مسجل بهذا البريد الإلكتروني';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'كلمة المرور أو البريد الإلكتروني غير صحيح';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'صيغة البريد الإلكتروني غير صحيحة';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'تم تعطيل هذا الحساب من قبل الإدارة';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تسجيل الدخول: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: GhaziTheme.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.local_gas_station,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('أهلاً بك في غازي',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: GhaziTheme.navy)),
              const SizedBox(height: 6),
              const Text('سجل دخولك لمتابعة وحجز طابور الغاز بسهولة',
                  style:
                      TextStyle(fontSize: 13, color: GhaziTheme.textSecondary)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon:
                      Icon(Icons.email_outlined, color: GhaziTheme.navy),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon:
                      const Icon(Icons.lock_outline, color: GhaziTheme.navy),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('تسجيل الدخول'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ليس لديك حساب؟ ',
                      style: TextStyle(color: GhaziTheme.textSecondary)),
                  GestureDetector(
                    onTap: widget.onNavigateToSignup,
                    child: const Text('إنشاء حساب جديد',
                        style: TextStyle(
                            color: GhaziTheme.orange,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
