import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (_isLoginMode) {
        await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await authProvider.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd: ${error.toString()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 72,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isLoginMode ? 'Witaj w GymlyPro' : 'Dołącz do nas!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode ? 'Zaloguj się, by trenować z nami' : 'Stwórz konto i śledź swoje rekordy',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 32),
                if (!_isLoginMode)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        labelText: 'Nazwa użytkownika',
                        prefixIcon: Icon(Icons.person_outline, color: Color(0xFF64748B)),
                      ),
                      validator: (value) => (value == null || value.trim().length < 3) ? 'Minimum 3 znaki' : null,
                    ),
                  ),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    labelText: 'Adres email',
                    prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF64748B)),
                  ),
                  validator: (value) => (value == null || !value.contains('@')) ? 'Podaj poprawny email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'Hasło',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64748B)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                    ),
                  ),
                  validator: (value) => (value == null || value.length < 6) ? 'Minimum 6 znaków' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    shadowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                    elevation: 8,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          _isLoginMode ? 'ZALOGUJ SIĘ' : 'ZAREJESTRUJ SIĘ',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
                        ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _isLoading ? null : _switchMode,
                  child: Text(
                    _isLoginMode ? 'Nie masz konta? Zarejestruj się' : 'Masz już konto? Zaloguj się',
                    style: const TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}