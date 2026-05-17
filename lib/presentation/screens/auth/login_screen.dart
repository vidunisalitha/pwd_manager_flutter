import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePin = true;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _attemptBiometricAuth();
  }

  void _attemptBiometricAuth() async {
    final authProvider = context.read<AuthProvider>();
    bool success = await authProvider.loginWithBiometrics();
    if (success && mounted) {
      // If biometric login succeeds, nothing else needed here because
      // AuthProvider will notify listeners and navigate from higher-level UI.
    }
  }

  void _handlePinLogin() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final success = await context.read<AuthProvider>().login(_pinController.text);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid PIN'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = context.select((AuthProvider ap) => ap.userName) ?? 'User';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = isDark ? const Color(0xFF181A20) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFF9AA3AF) : const Color(0xFF6B7280);
    final inputFill = isDark ? const Color(0xFF111318) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                'lib/assets/logo_transparent.png',
                width: 72,
                height: 72,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Welcome back, $username',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 30,),
            TextField(
              controller: _pinController,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 10,
              ),
              decoration: InputDecoration(
                hintText: '....',
                hintStyle: TextStyle(
                  letterSpacing: 10,
                  color: subtitleColor,
                ),
                fillColor: inputFill,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF2A2F37) : const Color(0xFFD8DCE3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF2A2F37) : const Color(0xFFD8DCE3)),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePin
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if(_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _handlePinLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Unlock Your Vault'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _attemptBiometricAuth,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Text('Use Biometrics'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}