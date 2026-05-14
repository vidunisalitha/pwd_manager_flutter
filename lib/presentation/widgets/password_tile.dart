import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pwd_manager_flutter/data/models/account_model.dart';

class PasswordTile extends StatefulWidget {
  final AccountModel account;
  final bool isPeeking;

  const PasswordTile(
    {
      super.key,
      required this.account,
      required this.isPeeking
    }
  );

  @override
  State<PasswordTile> createState() => _PasswordTileState();
}

class _PasswordTileState extends State<PasswordTile> {
  bool _individualVisibility = false;

  @override
  Widget build(BuildContext context) {
    final bool showPlainText = _individualVisibility || widget.isPeeking;
    final String displayPassword = showPlainText ? (widget.account.decryptedPassword ?? "Error") : '........';
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(12)
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(widget.account.serviceName[0].toUpperCase()),
        ),
        title: Text(
          widget.account.serviceName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.account.username),
            const SizedBox(height: 4,),
            Text(
              displayPassword,
              style: TextStyle(
                fontFamily: showPlainText ? 'monospace' : null,
                letterSpacing: showPlainText ? 0 : 2,
                color: showPlainText ? Colors.blueGrey : Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                showPlainText ? Icons.visibility : Icons.visibility_off
              ),
              onPressed: () => setState(() => _individualVisibility = !_individualVisibility),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {}
            ),
          ],
        ),
      ),
    );
  }
}