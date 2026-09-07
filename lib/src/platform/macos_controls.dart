import 'package:flutter/services.dart';

import '../widgets/ios26/ios26_alert_dialog.dart';
import '../widgets/ios26/ios26_popup_menu_button.dart';

const MethodChannel _channel = MethodChannel('adaptive_platform_ui/macos');

/// Native AppKit menus and alerts. Failures fall back to Flutter Cupertino.
class MacOSControls {
  MacOSControls._();

  static Future<int?> showMenu({
    required double x,
    required double y,
    required double width,
    required double height,
    required double viewWidth,
    required double viewHeight,
    required List<AdaptivePopupMenuEntry> items,
  }) async {
    final payload = <Map<String, Object?>>[];
    for (var i = 0; i < items.length; i++) {
      final entry = items[i];
      if (entry is AdaptivePopupMenuDivider) {
        payload.add(<String, Object?>{'type': 'divider', 'index': i});
        continue;
      }
      if (entry is AdaptivePopupMenuItem) {
        payload.add(<String, Object?>{
          'type': 'item',
          'index': i,
          'label': entry.label,
          'symbol': entry.icon is String ? entry.icon as String : null,
          'enabled': entry.enabled,
          'destructive': entry.isDestructive,
          'selected': entry.selected,
        });
      }
    }

    try {
      return await _channel.invokeMethod<int>('showMenu', {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'viewWidth': viewWidth,
        'viewHeight': viewHeight,
        'items': payload,
      });
    } on PlatformException {
      return null;
    }
  }

  static Future<int?> showAlert({
    required String title,
    String? message,
    required List<AlertAction> actions,
  }) async {
    try {
      return await _channel.invokeMethod<int>('showAlert', {
        'title': title,
        'message': message,
        'actions': [
          for (final action in actions)
            <String, Object?>{
              'title': action.title,
              'style': action.style.name,
              'enabled': action.enabled,
            },
        ],
      });
    } on PlatformException {
      return null;
    }
  }
}
