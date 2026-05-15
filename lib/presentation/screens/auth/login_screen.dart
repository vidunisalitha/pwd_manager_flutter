import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _attemptBiometricAuth();
  }

  void _attemptBiometricAuth() async {
    final authProvider = context.read<AuthProvider>();
    bool success = await authProvider.loginWithBiometrics();

    if(success && mounted){}
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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              child: Icon(
                Icons.person,
                size: 50,
              ),
            ),
            const Divider(height: 20,),
            Text(
              'Welcome back, $username',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30,),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 10,
              ),
              decoration: const InputDecoration(
                hintText: '....',
                hintStyle: TextStyle(
                  letterSpacing: 10,
                ),
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40,),
            if(_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handlePinLogin,
                      child: const Text('Unlock Your Vault'),
                    ),
                  ),
                  TextButton(
                    onPressed: _attemptBiometricAuth,
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