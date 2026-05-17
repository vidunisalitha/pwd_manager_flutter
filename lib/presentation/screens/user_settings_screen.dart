import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pwd_manager_flutter/core/crypto/hasher.dart';
import 'package:pwd_manager_flutter/presentation/providers/app_theme_provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/auth_provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/vault_provider.dart';

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final _usernameController = TextEditingController();
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _didLoad = false;
  bool _biometricEnabled = false;
  bool _savingCredentials = false;
  bool _savingBiometrics = false;
  bool _obscureCurrentPin = true;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoad) {
      return;
    }

    final auth = context.read<AuthProvider>();
    _usernameController.text = auth.userName ?? '';
    _didLoad = true;

    auth.isBiometricEnabled().then((enabled) {
      if (!mounted) {
        return;
      }

      setState(() => _biometricEnabled = enabled);
    });
  }

  InputDecoration _fieldDecoration(
    TextTheme textTheme, {
    required String hintText,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF111318) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2F37) : const Color(0xFFD8DCE3);
    final mutedColor = isDark ? const Color(0xFF8A93A3) : const Color(0xFF98A2B3);

    return InputDecoration(
      hintText: hintText,
      hintStyle: textTheme.bodyLarge?.copyWith(
        color: mutedColor,
        letterSpacing: 0.2,
      ),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF059669), width: 1.2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _resetCredentialFields() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _usernameController.text = auth.userName ?? '';
      _currentPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();
    });
  }

  Future<void> _showMessage(String message) async {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateCredentials() async {
    final auth = context.read<AuthProvider>();
    final vault = context.read<VaultProvider>();
    final oldMasterKey = auth.masterKey;

    final username = _usernameController.text.trim();
    final currentPin = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (username.isEmpty ||
        currentPin.isEmpty ||
        newPin.isEmpty ||
        confirmPin.isEmpty) {
      await _showMessage('Please fill in all fields');
      return;
    }

    if (newPin != confirmPin) {
      await _showMessage('New PINs do not match');
      return;
    }

    if (oldMasterKey == null) {
      await _showMessage('Session expired. Please sign in again.');
      return;
    }

    final currentPinValid = await auth.verifyCurrentPin(currentPin);
    if (!currentPinValid) {
      await _showMessage('Current PIN is invalid');
      return;
    }

    setState(() => _savingCredentials = true);

    try {
      final hashResult = await Hasher.hashPinForStorage(newPin);
      final masterHash = hashResult['hash'];
      final salt = hashResult['salt'];

      if (masterHash == null || salt == null) {
        throw Exception('Unable to generate new credentials');
      }

      final newMasterKey = await Hasher.deriveKey(newPin, base64Decode(salt));

      final rotated = await vault.rotateVaultEncryptionKey(
        oldMasterKey: oldMasterKey,
        newMasterKey: newMasterKey,
      );

      if (!rotated) {
        throw Exception('Unable to re-encrypt your vault');
      }

      final saved = await auth.updateCredentials(
        username: username,
        currentPin: currentPin,
        newPin: newPin,
        masterHash: masterHash,
        salt: salt,
        newMasterKey: newMasterKey,
      );

      if (!saved) {
        throw Exception('Unable to save your credentials');
      }

      if (!mounted) {
        return;
      }

      await _resetCredentialFields();
      await _showMessage('Credentials updated');
    } catch (e) {
      await _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _savingCredentials = false);
      }
    }
  }

  Future<String?> _promptForPin({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return _PinPromptDialog(
          title: title,
          message: message,
          onCancel: () => Navigator.pop(dialogContext),
          onConfirm: (pin) => Navigator.pop(dialogContext, pin),
        );
      },
    );
    return result;
  }

  Future<void> _toggleBiometrics(bool enabled) async {
    final pin = await _promptForPin(
      title: enabled ? 'Enable Biometrics' : 'Disable Biometrics',
      message: 'Re-enter your PIN to confirm this change.',
    );

    if (pin == null || pin.isEmpty) {
      return;
    }

    setState(() => _savingBiometrics = true);

    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.setBiometricEnabled(
        pin: pin,
        enabled: enabled,
      );

      if (!success) {
        await _showMessage('PIN validation failed');
        return;
      }

      if (mounted) {
        setState(() => _biometricEnabled = enabled);
      }
    } finally {
      if (mounted) {
        setState(() => _savingBiometrics = false);
      }
    }
  }

  Future<void> _logout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Logout?'),
          content: const Text(
            'You will need to sign in again to access your vault.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : const Color(0xFFE11D48),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF5A1B2A)
                      : const Color(0xFFFCA5A5),
                ),
                backgroundColor: isDark
                    ? const Color(0xFF6A1F32)
                    : const Color(0xFFFDE8EE),
                textStyle: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await context.read<AuthProvider>().logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF181A20) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2F37) : const Color(0xFFE4E7EC);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFF9AA3AF) : const Color(0xFF667085);
    final themeProvider = context.watch<AppThemeProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Text(
                    'Settings',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: borderColor),
              const SizedBox(height: 24),
              Text(
                'USER INFORMATION',
                style: textTheme.labelLarge?.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F101828),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Edit Username',
                      style: textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _usernameController,
                      decoration: _fieldDecoration(
                        textTheme,
                        hintText: 'Username',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(height: 1, color: borderColor),
                    const SizedBox(height: 14),
                    Text(
                      'Update PIN',
                      style: textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _currentPinController,
                      obscureText: _obscureCurrentPin,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: _fieldDecoration(
                        textTheme,
                        hintText: 'Current PIN (••••)',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrentPin
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() =>
                              _obscureCurrentPin = !_obscureCurrentPin),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPinController,
                      obscureText: _obscureNewPin,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: _fieldDecoration(
                        textTheme,
                        hintText: 'New PIN (••••)',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNewPin
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscureNewPin = !_obscureNewPin),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPinController,
                      obscureText: _obscureConfirmPin,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: _fieldDecoration(
                        textTheme,
                        hintText: 'Confirm New PIN',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPin
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() =>
                              _obscureConfirmPin = !_obscureConfirmPin),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _savingCredentials
                                  ? null
                                  : _updateCredentials,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _savingCredentials ? 'Updating...' : 'Update',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _savingCredentials
                                  ? null
                                  : _resetCredentialFields,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? const Color(0xFF23262D)
                                    : const Color(0xFFF2F4F7),
                                foregroundColor: isDark
                                    ? const Color(0xFFE5E7EB)
                                    : const Color(0xFF1F2937),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'APPLICATION PREFERENCES',
                style: textTheme.labelLarge?.copyWith(
                  color: subtitleColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F101828),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Theme',
                      style: textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ThemeOption(
                            label: 'Light',
                            icon: Icons.light_mode_outlined,
                            selected:
                                themeProvider.themeMode == ThemeMode.light,
                            onTap: () => context
                                .read<AppThemeProvider>()
                                .setThemeMode(ThemeMode.light),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ThemeOption(
                            label: 'Dark',
                            icon: Icons.dark_mode_outlined,
                            selected: themeProvider.themeMode == ThemeMode.dark,
                            onTap: () => context
                                .read<AppThemeProvider>()
                                .setThemeMode(ThemeMode.dark),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ThemeOption(
                            label: 'System',
                            icon: Icons.desktop_windows_outlined,
                            selected:
                                themeProvider.themeMode == ThemeMode.system,
                            onTap: () => context
                                .read<AppThemeProvider>()
                                .setThemeMode(ThemeMode.system),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(height: 1, color: borderColor),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Biometric Login',
                                style: textTheme.titleMedium?.copyWith(
                                  color: titleColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Enabling biometrics will require your current PIN for verification.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _biometricEnabled,
                          onChanged: _savingBiometrics
                              ? null
                              : _toggleBiometrics,
                          activeColor: const Color(0xFF059669),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : const Color(0xFFE11D48),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF5A1B2A)
                          : const Color(0xFFFCA5A5),
                    ),
                    backgroundColor: isDark
                        ? const Color(0xFF6A1F32)
                        : const Color(0xFFFDE8EE),
                    textStyle: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinPromptDialog extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onCancel;
  final ValueChanged<String> onConfirm;

  const _PinPromptDialog({
    required this.title,
    required this.message,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<_PinPromptDialog> createState() => _PinPromptDialogState();
}

class _PinPromptDialogState extends State<_PinPromptDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.message, style: textTheme.bodyMedium),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              labelText: 'PIN',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => widget.onConfirm(_controller.text.trim()),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = const Color(0xFF06B36B);
    final backgroundColor = selected
      ? (isDark ? const Color(0xFF10291F) : const Color(0xFFEAF9F1))
      : (isDark ? const Color(0xFF111318) : Colors.white);
    final borderColor = selected
      ? selectedColor
      : (isDark ? const Color(0xFF2A2F37) : const Color(0xFFD0D5DD));
    final textColor = selected
      ? selectedColor
      : (isDark ? const Color(0xFFD1D5DB) : const Color(0xFF344054));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
