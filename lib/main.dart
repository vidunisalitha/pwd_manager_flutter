import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/auth_provider.dart';
import 'package:pwd_manager_flutter/presentation/screens/auth/login_screen.dart';
import 'package:pwd_manager_flutter/presentation/screens/auth/signup_screen.dart';
import 'package:pwd_manager_flutter/presentation/screens/main_vault_screen.dart';

void main() {
  runApp(const MaterialApp(
    home: RootWrapper(),
  ));
}

class RootWrapper extends StatelessWidget {
  const RootWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if(auth.status == AuthStatus.unknown) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if(auth.status == AuthStatus.firstTimer) {
          return const SignupScreen();
        }

        if(auth.status == AuthStatus.authenticated) {
          return const MainVaultScreen();
        }

        return LoginScreen();
      }
    );
  }
}

