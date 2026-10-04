import 'package:convetchat/core/di/locator.dart';
import 'package:convetchat/core/platform_style.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

class const AdaptiveTextField({
  super.key,
  final TextEditingController? controller,
  final String? label,
  final String? hint,
  final String? prefixText,
  final String? suffixText,
  final bool obscureText = false,
  final bool readOnly = false,
  final bool enabled = true,
  final TextInputType? keyboardType,
  final TextInputAction? textInputAction,
  final ValueChanged<String>? onChanged,
  final ValueChanged<String>? onSubmitted,
  final int? maxLines,
  final int? minLines,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prefix = prefixText;
    final suffix = suffixText;
    if (getIt<PlatformStyle>().isCupertino) {
      return CupertinoTextField(
        controller: controller,
        placeholder: label,
        prefix: prefix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(prefix),
              ),
        suffix: suffix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(suffix),
              ),
        obscureText: obscureText,
        readOnly: readOnly,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        maxLines: maxLines ?? 1,
        minLines: minLines,
        decoration: BoxDecoration(
          borderRadius: .circular(50),
          color: CupertinoColors.systemFill,
        ),
      );
    }
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        suffixText: suffixText,
      ),
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      maxLines: maxLines ?? 1,
      minLines: minLines,
    );
  }
}
