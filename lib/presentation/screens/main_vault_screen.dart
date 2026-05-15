import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/auth_provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/vault_provider.dart';
import 'package:pwd_manager_flutter/presentation/widgets/add_service_model.dart';
import 'package:pwd_manager_flutter/presentation/widgets/password_tile.dart';

class MainVaultScreen extends StatefulWidget {
  const MainVaultScreen({super.key});

  @override
  State<MainVaultScreen> createState() => _MainVaultScreenState();
}

class _MainVaultScreenState extends State<MainVaultScreen> {
  bool _isPeeking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Vault')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (query) =>
                  context.read<VaultProvider>().searchAccounts(
                    query,
                    context.read<AuthProvider>().masterKey!,
                  ),
            ),
          ),
          Expanded(
            child: Consumer<VaultProvider>(
              builder: (context, vault, child) {
                if (vault.accounts.isEmpty)
                  return const Center(child: Text('No Services Added Yet'));
                return ListView.builder(
                  itemCount: vault.accounts.length,
                  itemBuilder: (context, index) => PasswordTile(
                    account: vault.accounts[index],
                    isPeeking: _isPeeking,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onLongPressStart: (_) => setState(() => _isPeeking = true),
            onLongPressEnd: (_) => setState(() => _isPeeking = false),
            child: FloatingActionButton(
              onPressed: () {},
              heroTag: 'peek',
              backgroundColor: _isPeeking ? Colors.red : Colors.orange,
              child: Icon(_isPeeking ? Icons.visibility : Icons.visibility_off),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => const AddServiceModel(),
            ),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
