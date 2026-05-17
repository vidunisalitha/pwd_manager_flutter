import 'package:flutter/material.dart';
import 'package:pwd_manager_flutter/data/models/account_model.dart';

class PasswordTile extends StatefulWidget {
  final AccountModel account;
  final bool isPeeking;
  final VoidCallback? onLongPress;

  const PasswordTile({
    super.key,
    required this.account,
    required this.isPeeking,
    this.onLongPress,
  });

  @override
  State<PasswordTile> createState() => _PasswordTileState();
}

class _PasswordTileState extends State<PasswordTile> {
  bool _individualVisibility = false;

  static const List<Color> _avatarPalette = [
    Color(0xFF2563EB),
    Color(0xFF0891B2),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
    Color(0xFF0D9488),
    Color(0xFF4F46E5),
  ];

  Color _avatarColor(String serviceName) {
    final hash = serviceName.trim().toLowerCase().hashCode;
    return _avatarPalette[hash.abs() % _avatarPalette.length];
  }

  String _serviceInitial(String serviceName) {
    final trimmed = serviceName.trim();
    if (trimmed.isEmpty) {
      return '?';
    }

    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool showPlainText = _individualVisibility || widget.isPeeking;
    final String displayPassword = showPlainText
        ? (widget.account.decryptedPassword ?? "Error")
        : '........';
    final avatarColor = _avatarColor(widget.account.serviceName);
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF181A20) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2F37) : const Color(0xFFD6DAE1);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFFB0B7C3) : const Color(0xFF6B7280);
    final passwordColor = isDark ? const Color(0xFF97A0AE) : const Color(0xFF9CA3AF);
    final iconColor = isDark ? const Color(0xFF97A0AE) : const Color(0xFF9CA3AF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        minVerticalPadding: 8,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onLongPress: widget.onLongPress,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: avatarColor,
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: Text(
            _serviceInitial(widget.account.serviceName),
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          widget.account.serviceName,
          style: textTheme.titleMedium?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 1),
            Text(
              widget.account.username,
              style: textTheme.bodyMedium?.copyWith(
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayPassword,
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: showPlainText ? 'monospace' : null,
                letterSpacing: showPlainText ? 0 : 2.5,
                color: passwordColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            showPlainText ? Icons.visibility : Icons.visibility_outlined,
            color: iconColor,
          ),
          onPressed: () =>
              setState(() => _individualVisibility = !_individualVisibility),
        ),
      ),
    );
  }
}
