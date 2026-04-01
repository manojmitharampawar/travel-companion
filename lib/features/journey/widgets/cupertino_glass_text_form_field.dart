import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:travel_companion/core/theme/glass_theme.dart';

class CupertinoGlassTextFormField extends FormField<String> {
  CupertinoGlassTextFormField({
    super.key,
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffix,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    int? maxLength,
    ValueChanged<String>? onChanged,
    super.validator,
  }) : super(
         initialValue: controller.text,
         builder: (field) {
           final g = GlassColors.of(field.context);
           final hasError = field.errorText != null;
           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 labelText,
                 style: TextStyle(
                   fontSize: 12,
                   fontWeight: FontWeight.w600,
                   color: g.textSecondary,
                 ),
               ),
               const SizedBox(height: 6),
               ClipRRect(
                 borderRadius: BorderRadius.circular(14),
                 child: BackdropFilter(
                   filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                   child: Container(
                     decoration: BoxDecoration(
                       color: g.inputFill,
                       borderRadius: BorderRadius.circular(14),
                       border: Border.all(
                         color: hasError
                             ? const Color(0xFFE74C3C)
                             : g.inputBorder,
                         width: hasError ? 1.2 : 1,
                       ),
                     ),
                     child: CupertinoTextField(
                       controller: controller,
                       keyboardType: keyboardType,
                       textInputAction: textInputAction,
                       inputFormatters: maxLength != null
                           ? [LengthLimitingTextInputFormatter(maxLength)]
                           : null,
                       style: TextStyle(color: g.textAlpha(0.92), fontSize: 15),
                       placeholder: hintText,
                       placeholderStyle: TextStyle(
                         color: g.textHint,
                         fontSize: 14,
                       ),
                       padding: const EdgeInsets.symmetric(
                         horizontal: 12,
                         vertical: 13,
                       ),
                       prefix: prefixIcon != null
                           ? Padding(
                               padding: const EdgeInsets.only(
                                 left: 10,
                                 right: 6,
                               ),
                               child: Icon(
                                 prefixIcon,
                                 size: 18,
                                 color: g.textSecondary,
                               ),
                             )
                           : null,
                       suffix: suffix,
                       decoration: const BoxDecoration(
                         color: Color(0x00000000),
                       ),
                       onChanged: (value) {
                         field.didChange(value);
                         onChanged?.call(value);
                       },
                     ),
                   ),
                 ),
               ),
               if (helperText != null && !hasError)
                 Padding(
                   padding: const EdgeInsets.only(top: 6, left: 2),
                   child: Text(
                     helperText,
                     style: TextStyle(fontSize: 11, color: g.textTertiary),
                   ),
                 ),
               if (hasError)
                 Padding(
                   padding: const EdgeInsets.only(top: 6, left: 2),
                   child: Text(
                     field.errorText!,
                     style: const TextStyle(
                       fontSize: 11,
                       color: Color(0xFFE74C3C),
                     ),
                   ),
                 ),
               if (maxLength != null)
                 Padding(
                   padding: const EdgeInsets.only(top: 4, right: 4),
                   child: Align(
                     alignment: Alignment.centerRight,
                     child: Text(
                       '${controller.text.length}/$maxLength',
                       style: TextStyle(fontSize: 11, color: g.textHint),
                     ),
                   ),
                 ),
             ],
           );
         },
       );
}
