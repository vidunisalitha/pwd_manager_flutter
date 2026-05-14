import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      appBar: AppBar(
        title: const Text('My Vault')
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(data),
          ),
        ],
      ),
    );
  }
}