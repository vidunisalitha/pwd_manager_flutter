import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  final _userController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _userController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if(_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pins do not match')),
      );
      return;
    }

    final success = await context.read<AuthProvider>().signUp(
      _userController.text,
      _pinController.text,
    );

    if(success && mounted){}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
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
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Create Your Vault',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            SizedBox(height: 30),
            TextField(
              controller: _userController,
              decoration: InputDecoration(
                labelText: 'Username',
                filled: true,
                fillColor: inputFill,
                labelStyle: TextStyle(color: subtitleColor),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? const Color(0xFF2A2F37) : const Color(0xFFD8DCE3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? const Color(0xFF2A2F37) : const Color(0xFFD8DCE3)),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _pinController,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: 'Set 4-Digit PIN',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: inputFill,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePin
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              obscureText: _obscureConfirmPin,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: 'Confirm Your PIN',
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? const Color(0xFF2A2F37) : const Color(0xFFD8DCE3)),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPin
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() =>
                      _obscureConfirmPin = !_obscureConfirmPin),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _handleSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                child: const Text('Create Vault'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}