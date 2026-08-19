import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../platform/platform_info.dart';

/// Platform-adaptive modal sheet.
///
/// iOS: the system stacked-card sheet (`CupertinoSheetRoute`) — rounded
/// display-concentric corners, pull-to-dismiss, and the presenting page
/// scaling back, exactly like UISheetPresentationController.
/// Android/other: a standard modal bottom sheet.
class AdaptiveSheet {
  const AdaptiveSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool useRootNavigator = true,
    Color? barrierColor,
  }) {
    if (PlatformInfo.isIOS) {
      return showCupertinoSheet<T>(
        context: context,
        useNestedNavigation: false,
        pageBuilder: builder,
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: useRootNavigator,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor,
      builder: builder,
    );
  }
}
