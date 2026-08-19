import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../platform/platform_info.dart';
import 'ios26/ios26_text_field.dart';

/// Platform-adaptive search field.
///
/// iOS 26+: native UISearchTextField (system magnifier, clear button, fill).
/// Older iOS: CupertinoSearchTextField. Android/other: Material TextField
/// with a search affordance.
class AdaptiveSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Color? backgroundColor;
  final TextStyle? style;
  final TextStyle? placeholderStyle;
  final double height;
  final bool autofocus;

  const AdaptiveSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.backgroundColor,
    this.style,
    this.placeholderStyle,
    this.height = 38.0,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26TextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        style: IOS26TextFieldStyle.search,
        fontSize: style?.fontSize ?? 17.0,
        textColor: style?.color,
        placeholderColor: placeholderStyle?.color,
        backgroundColor: backgroundColor,
        // A custom background paints the raw view rect — keep it a capsule.
        cornerRadius: backgroundColor != null ? height / 2 : null,
        textInputAction: TextInputAction.search,
        autofocus: autofocus,
        height: height,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      );
    }

    if (PlatformInfo.isIOS) {
      return CupertinoSearchTextField(
        controller: controller,
        focusNode: focusNode,
        placeholder: placeholder,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        backgroundColor: backgroundColor,
        style: style,
        placeholderStyle: placeholderStyle,
        autofocus: autofocus,
        borderRadius: BorderRadius.circular(height / 2),
      );
    }

    return SizedBox(
      height: height + 6,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        style: style,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: placeholderStyle,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: backgroundColor,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(height / 2), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
