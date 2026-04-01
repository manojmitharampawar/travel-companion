import 'package:flutter/cupertino.dart';
import 'package:travel_companion/features/journey/widgets/cupertino_glass_text_form_field.dart';

class GlassCupertinoTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? helperText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const GlassCupertinoTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffix,
    this.helperText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLength,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoGlassTextFormField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffix: suffix,
      helperText: helperText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
