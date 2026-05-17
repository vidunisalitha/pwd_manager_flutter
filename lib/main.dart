import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/app_theme_provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/auth_provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/vault_provider.dart';
import 'package:pwd_manager_flutter/presentation/screens/auth/login_screen.dart';
import 'package:pwd_manager_flutter/presentation/screens/auth/signup_screen.dart';
import 'package:pwd_manager_flutter/presentation/screens/main_vault_screen.dart';

ThemeData _buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = isDark
      ? const ColorScheme.dark(
          primary: Color(0xFF11C48A),
          secondary: Color(0xFF34D399),
          surface: Color(0xFF181A20),
          background: Color(0xFF0B0D10),
          onSurface: Colors.white,
          onBackground: Colors.white,
          onPrimary: Color(0xFF04130C),
        )
      : ColorScheme.fromSeed(
          seedColor: const Color(0xFF059669),
          brightness: Brightness.light,
        );

  final scaffoldBackgroundColor = isDark ? const Color(0xFF0B0D10) : Colors.white;
  final surfaceColor = isDark ? const Color(0xFF181A20) : Colors.white;
  final outlineColor = isDark ? const Color(0xFF2A2F37) : const Color(0xFFD8DCE3);
  final mutedTextColor = isDark ? const Color(0xFF9AA3AF) : const Color(0xFF6B7280);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    canvasColor: scaffoldBackgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBackgroundColor,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: outlineColor),
      ),
    ),
    dividerTheme: DividerThemeData(color: outlineColor, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF111318) : const Color(0xFFF8FAFC),
      hintStyle: TextStyle(color: mutedTextColor),
      labelStyle: TextStyle(color: mutedTextColor),
      helperStyle: TextStyle(color: mutedTextColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: outlineColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: outlineColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: outlineColor),
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? const Color(0xFF1F2430) : const Color(0xFF111827),
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: Typography.material2021().black.apply(
          bodyColor: isDark ? Colors.white : const Color(0xFF111827),
          displayColor: isDark ? Colors.white : const Color(0xFF111827),
        ),
  );
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (_) => VaultProvider()),
        ChangeNotifierProvider(
          create: (_) => AppThemeProvider()..loadThemeMode(),
        ),
      ],
      child: Consumer<AppThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: _buildAppTheme(Brightness.light),
            darkTheme: _buildAppTheme(Brightness.dark),
            home: const RootWrapper(),
          );
        },
      ),
    ),
  );
}

class RootWrapper extends StatelessWidget {
  const RootWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.status == AuthStatus.unknown) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (auth.status == AuthStatus.firstTimer) {
          return const SignupScreen();
        }

        if (auth.status == AuthStatus.authenticated) {
          return const MainVaultScreen();
        }

        return LoginScreen();
      },
    );
  }
}
