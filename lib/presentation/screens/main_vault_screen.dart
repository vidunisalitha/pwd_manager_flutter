import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/auth_provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/vault_provider.dart';
import 'package:pwd_manager_flutter/presentation/widgets/add_service_model.dart';
import 'package:pwd_manager_flutter/presentation/widgets/password_tile.dart';
import 'package:pwd_manager_flutter/presentation/widgets/update_service_model.dart';
import 'package:pwd_manager_flutter/presentation/screens/user_settings_screen.dart';

class MainVaultScreen extends StatefulWidget {
  const MainVaultScreen({super.key});

  @override
  State<MainVaultScreen> createState() => _MainVaultScreenState();
}

class _MainVaultScreenState extends State<MainVaultScreen> {
  bool _isPeeking = false;
  String _query = '';
  bool _didLoadAccounts = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoadAccounts) {
      return;
    }

    final masterKey = context.read<AuthProvider>().masterKey;
    if (masterKey == null) {
      return;
    }

    _didLoadAccounts = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VaultProvider>().loadAccounts(masterKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = colorScheme.surface;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = isDark ? const Color(0xFF9AA3AF) : const Color(0xFF6B7280);
    final accentColor = colorScheme.primary;
    final userName = context.select((AuthProvider auth) => auth.userName) ?? '';
    final userInitial = userName.trim().isNotEmpty
        ? userName.trim().characters.first.toUpperCase()
        : '?';

    void openUpdateSheet(account) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => UpdateServiceModel(account: account),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Consumer<VaultProvider>(
          builder: (context, vault, child) {
            if (vault.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final normalizedQuery = _query.trim().toLowerCase();
            final displayedAccounts = normalizedQuery.isEmpty
                ? vault.accounts
                : vault.accounts.where((account) {
                    return account.serviceName.toLowerCase().contains(
                          normalizedQuery,
                        ) ||
                        account.username.toLowerCase().contains(
                          normalizedQuery,
                        );
                  }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    children: [
                      Image.asset(
                        'lib/assets/logo_transparent.png',
                        width: 48,
                        height: 48,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'PeekAKey',
                        style: textTheme.titleLarge?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserSettingsScreen(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: isDark
                              ? const Color(0xFF2A2F37)
                              : const Color(0xFFE5E7EB),
                          child: Text(
                            userInitial,
                            style: textTheme.labelLarge?.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF4B5563),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      hintStyle: textTheme.bodyLarge?.copyWith(
                        color: textSecondary,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF111318)
                          : const Color(0xFFEDEFF3),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (query) => setState(() => _query = query),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Row(
                    children: [
                      Text(
                        'YOUR SERVICES',
                        style: textTheme.labelLarge?.copyWith(
                          color: textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${displayedAccounts.length} items',
                        style: textTheme.labelLarge?.copyWith(
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: vault.accounts.isEmpty
                      ? const Center(
                          child: Text(
                            'No services added yet. Tap + to create your first one.',
                          ),
                        )
                      : displayedAccounts.isEmpty
                      ? Center(
                          child: Text(
                            'No matching services found',
                            style: textTheme.bodyMedium?.copyWith(
                              color: textSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 130),
                          itemCount: displayedAccounts.length,
                          itemBuilder: (context, index) => PasswordTile(
                            account: displayedAccounts[index],
                            isPeeking: _isPeeking,
                            onLongPress: () =>
                                openUpdateSheet(displayedAccounts[index]),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (context) => const AddServiceModel(),
            ),
            heroTag: 'add',
            shape: const CircleBorder(),
            elevation: 2,
            backgroundColor: isDark ? const Color(0xFF1F2430) : Colors.white,
            foregroundColor: isDark ? Colors.white : const Color(0xFF1F2937),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onLongPressStart: (_) => setState(() => _isPeeking = true),
            onLongPressEnd: (_) => setState(() => _isPeeking = false),
            child: FloatingActionButton(
              onPressed: () {},
              heroTag: 'peek',
              shape: const CircleBorder(),
              elevation: 3,
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              child: Icon(
                _isPeeking ? Icons.visibility : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
