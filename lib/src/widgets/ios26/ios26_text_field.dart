import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Style of the native text field.
enum IOS26TextFieldStyle {
  /// Plain UITextField.
  plain,

  /// UISearchTextField: system magnifier, clear button, and quiet fill.
  search,
}

/// A native single-line iOS text field rendered by UIKit.
///
/// Text and focus are kept in sync with the optional [controller] and
/// [focusNode] over a method channel. Multiline input, inline Flutter
/// widgets (prefix/suffix), and custom input formatters are not supported —
/// use the drawn `AdaptiveTextField` fallback for those.
class IOS26TextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final IOS26TextFieldStyle style;
  final double fontSize;
  final Color? textColor;
  final Color? placeholderColor;
  final Color? backgroundColor;
  final double? cornerRadius;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autocorrect;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final double height;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<bool>? onFocusChanged;

  const IOS26TextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.style = IOS26TextFieldStyle.plain,
    this.fontSize = 17.0,
    this.textColor,
    this.placeholderColor,
    this.backgroundColor,
    this.cornerRadius,
    this.keyboardType,
    this.textInputAction,
    this.autocorrect = true,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.height = 38.0,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
  });

  @override
  State<IOS26TextField> createState() => _IOS26TextFieldState();
}

class _IOS26TextFieldState extends State<IOS26TextField> {
  static int _nextId = 0;

  late final int _id;
  late final MethodChannel _channel;

  /// Last text value the native side knows about — guards the echo loop.
  String _nativeText = '';

  @override
  void initState() {
    super.initState();
    _id = _nextId++;
    _nativeText = widget.controller?.text ?? '';
    _channel = MethodChannel('adaptive_platform_ui/ios26_text_field_$_id');
    _channel.setMethodCallHandler(_handleMethod);
    widget.controller?.addListener(_controllerChanged);
    widget.focusNode?.addListener(_focusChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_controllerChanged);
    widget.focusNode?.removeListener(_focusChanged);
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  void didUpdateWidget(IOS26TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _channel.invokeMethod('setEnabled', {'enabled': widget.enabled});
    }
    if (oldWidget.placeholder != widget.placeholder) {
      _channel.invokeMethod('setPlaceholder', {'placeholder': widget.placeholder ?? ''});
    }
  }

  void _controllerChanged() {
    final text = widget.controller!.text;
    if (text != _nativeText) {
      _nativeText = text;
      _channel.invokeMethod('setText', {'text': text});
    }
  }

  void _focusChanged() {
    _channel.invokeMethod(widget.focusNode!.hasFocus ? 'focus' : 'unfocus');
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'textChanged':
        final text = (call.arguments as Map)['text'] as String? ?? '';
        _nativeText = text;
        final controller = widget.controller;
        if (controller != null && controller.text != text) {
          controller.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
        widget.onChanged?.call(text);
        break;
      case 'submitted':
        widget.onSubmitted?.call((call.arguments as Map)['text'] as String? ?? '');
        break;
      case 'focusChanged':
        widget.onFocusChanged?.call((call.arguments as Map)['focused'] as bool? ?? false);
        break;
    }
  }

  String get _keyboardTypeName {
    final type = widget.keyboardType;
    if (type == TextInputType.emailAddress) return 'email';
    if (type == TextInputType.number) return 'number';
    if (type == TextInputType.phone) return 'phone';
    if (type == const TextInputType.numberWithOptions(decimal: true)) return 'decimal';
    if (type == TextInputType.url) return 'url';
    return 'text';
  }

  String get _returnKeyName {
    switch (widget.textInputAction) {
      case TextInputAction.search:
        return 'search';
      case TextInputAction.send:
        return 'send';
      case TextInputAction.next:
        return 'next';
      case TextInputAction.go:
        return 'go';
      default:
        return 'done';
    }
  }

  String? _hex(Color? color) {
    if (color == null) return null;
    final argb = color.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    assert(!kIsWeb && Platform.isIOS, 'IOS26TextField is iOS-only');
    final brightness = MediaQuery.platformBrightnessOf(context);

    return SizedBox(
      height: widget.height,
      child: UiKitView(
        viewType: 'adaptive_platform_ui/ios26_text_field',
        creationParams: {
          'id': _id,
          'text': widget.controller?.text ?? '',
          'placeholder': widget.placeholder ?? '',
          'style': widget.style == IOS26TextFieldStyle.search ? 'search' : 'plain',
          'fontSize': widget.fontSize,
          if (_hex(widget.textColor) != null) 'textColor': _hex(widget.textColor),
          if (_hex(widget.placeholderColor) != null) 'placeholderColor': _hex(widget.placeholderColor),
          if (_hex(widget.backgroundColor) != null) 'backgroundColor': _hex(widget.backgroundColor),
          if (widget.cornerRadius != null) 'cornerRadius': widget.cornerRadius,
          'keyboardType': _keyboardTypeName,
          'returnKeyType': _returnKeyName,
          'autocorrect': widget.autocorrect,
          'obscureText': widget.obscureText,
          'enabled': widget.enabled,
          'isDark': brightness == Brightness.dark,
          'autofocus': widget.autofocus,
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}
