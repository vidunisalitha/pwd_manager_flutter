import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/auth_provider.dart';
import 'package:pwd_manager_flutter/presentation/providers/vault_provider.dart';

class AddServiceModel extends StatefulWidget {
  const AddServiceModel({super.key});

  @override
  State<AddServiceModel> createState() => _AddServiceModelState();
}

class _AddServiceModelState extends State<AddServiceModel> {
  final _serviceController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();

  void _save() async {
    if(_serviceController.text.isEmpty || _passwordController.text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final vault = context.read<VaultProvider>();

    await vault.addAccount(
      serviceName: _serviceController.text,
      username: _userController.text,
      password: _passwordController.text,
      masterKey: auth.masterKey!,
    );

    if(mounted) Navigator.pop(context);
  } 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add New Service',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 16,),
          TextField(
            controller: _serviceController,
            decoration: const InputDecoration(
              labelText: "Service Name (e.g. Gmail)"
            ),
          ),
          TextField(
            controller: _userController,
            decoration: const InputDecoration(
              labelText: "Username/ Email"
            ),
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Password"
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text("Save")
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}