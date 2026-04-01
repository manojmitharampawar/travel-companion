import 'package:flutter/cupertino.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class GlassConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const GlassConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final g = GlassColors.of(context);
    return CupertinoAlertDialog(
      title: Text(
        title,
        style: TextStyle(color: g.text, fontWeight: FontWeight.w700),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(message, style: TextStyle(color: g.textAlpha(0.8))),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onCancel,
          child: Text('Cancel', style: TextStyle(color: g.textAlpha(0.7))),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: onConfirm,
          child: Text(confirmLabel, style: TextStyle(color: confirmColor)),
        ),
      ],
    );
  }
}
