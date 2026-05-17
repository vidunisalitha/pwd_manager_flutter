import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pwd_manager_flutter/data/models/account_model.dart';
import 'package:pwd_manager_flutter/presentation/providers/auth_provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/vault_provider.dart';

class UpdateServiceModel extends StatefulWidget {
  final AccountModel account;

  const UpdateServiceModel({super.key, required this.account});

  @override
  State<UpdateServiceModel> createState() => _UpdateServiceModelState();
}

class _UpdateServiceModelState extends State<UpdateServiceModel> {
  late final TextEditingController _serviceController;
  late final TextEditingController _userController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _serviceController = TextEditingController(
      text: widget.account.serviceName,
    );
    _userController = TextEditingController(text: widget.account.username);
    _passwordController = TextEditingController(
      text: widget.account.decryptedPassword ?? '',
    );
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final id = widget.account.id;
    final auth = context.read<AuthProvider>();
    final masterKey = auth.masterKey;

    if (id == null || masterKey == null) {
      return;
    }

    if (_serviceController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    final vault = context.read<VaultProvider>();
    final success = await vault.updateAccount(
      id: id,
      serviceName: _serviceController.text,
      username: _userController.text,
      password: _passwordController.text,
      masterKey: masterKey,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteAccount() async {
    final id = widget.account.id;
    final auth = context.read<AuthProvider>();
    final masterKey = auth.masterKey;

    if (id == null || masterKey == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Delete Service?'),
          content: const Text(
            'This will permanently delete this service from your vault.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Theme.of(dialogContext).brightness == Brightness.dark
                      ? const Color(0xFF5A1B2A)
                      : const Color(0xFFFCA5A5),
                ),
                backgroundColor: Theme.of(dialogContext).brightness == Brightness.dark
                    ? const Color(0xFF6A1F32)
                    : const Color(0xFFFDE8EE),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() => _isDeleting = true);
    final vault = context.read<VaultProvider>();
    final success = await vault.deleteAccount(id, masterKey);

    if (!mounted) {
      return;
    }

    setState(() => _isDeleting = false);

    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF181A20) : Colors.white;
    final inputFill = isDark ? const Color(0xFF111318) : const Color(0xFFF8FAFC);
    final titleColor = colorScheme.onSurface;
    final bodyColor = isDark ? const Color(0xFFB0B7C3) : const Color(0xFF374151);
    final mutedColor = isDark ? const Color(0xFF8A93A3) : const Color(0xFF98A2B3);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    InputDecoration fieldDecoration({
      required String hintText,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        hintText: hintText,
        hintStyle: textTheme.titleMedium?.copyWith(
          color: mutedColor,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF059669), width: 1.2),
        ),
        suffixIcon: suffixIcon,
      );
    }

    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: surfaceColor,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Update Service',
                        style: textTheme.headlineSmall?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2F37) : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: isDark ? Colors.white70 : const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Service Name',
                  style: textTheme.titleMedium?.copyWith(
                    color: bodyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _serviceController,
                  textInputAction: TextInputAction.next,
                  decoration: fieldDecoration(hintText: 'e.g. Gmail, Netflix'),
                ),
                const SizedBox(height: 18),
                Text(
                  'Username / Email',
                  style: textTheme.titleMedium?.copyWith(
                    color: bodyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _userController,
                  textInputAction: TextInputAction.next,
                  decoration: fieldDecoration(hintText: 'user@example.com'),
                ),
                const SizedBox(height: 18),
                Text(
                  'Password',
                  style: textTheme.titleMedium?.copyWith(
                    color: bodyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  decoration: fieldDecoration(
                    hintText: 'Enter password',
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF98A2B3),
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(_isSaving ? 'Updating...' : 'Update Service'),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _isDeleting ? null : _deleteAccount,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : const Color(0xFFE11D48),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF5A1B2A) : const Color(0xFFFCA5A5),
                      ),
                      backgroundColor: isDark
                          ? const Color(0xFF6A1F32)
                          : const Color(0xFFFDE8EE),
                      textStyle: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(_isDeleting ? 'Deleting...' : 'Delete Service'),
                  ),
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
