import 'package:flutter/cupertino.dart';

class HomeActionSheetRow extends StatelessWidget {
  const HomeActionSheetRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = CupertinoTheme.of(context).textTheme.actionTextStyle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: style),
      ],
    );
  }
}
