import 'package:flutter/material.dart';
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_person,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 20,),
            Text(
              'Create Your Vault',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(height: 30),
            TextField(
              controller: _userController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder()
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Set 4-Digit PIN',
                border: OutlineInputBorder()
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Confirm Your PIN',
                border: OutlineInputBorder()
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSignup,
                child: Text('Create Vault'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}