import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../platform/macos_controls.dart';
import '../platform/platform_info.dart';
import '../style/sf_symbol_icon.dart';
import 'ios26/ios26_popup_menu_button.dart';

export 'ios26/ios26_popup_menu_button.dart'
    show
        AdaptivePopupMenuItem,
        AdaptivePopupMenuDivider,
        AdaptivePopupMenuEntry,
        PopupButtonStyle;

/// An adaptive popup menu button that renders platform-specific styles
class AdaptivePopupMenuButton<T> {
  AdaptivePopupMenuButton._();

  /// Creates a text-labeled popup menu button
  static Widget text<T>({
    Key? key,
    required String label,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry)
    onSelected,
    Color? tint,
    double height = 32.0,
    bool shrinkWrap = false,
    PopupButtonStyle buttonStyle = PopupButtonStyle.plain,
  }) {
    if (PlatformInfo.isMacOS) {
      return _MacOSPopupMenuButton<T>(
        label: label,
        items: items,
        onSelected: onSelected,
        height: height,
      );
    }

    // iOS 26+ - Use native iOS 26 popup menu button
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26PopupMenuButton<T>(
        buttonLabel: label,
        items: items,
        onSelected: onSelected,
        tint: tint,
        height: height,
        shrinkWrap: shrinkWrap,
        buttonStyle: buttonStyle,
      );
    }

    // Android - Use Material PopupMenuButton
    if (PlatformInfo.isAndroid) {
      return _MaterialPopupMenuButton<T>(
        label: label,
        items: items,
        onSelected: onSelected,
        tint: tint,
        height: height,
      );
    }

    // iOS <26 (iOS 18 and below) - Use CupertinoButton with action sheet (iOS fallback)
    return _iosLegacyButton<T>(label: label, items: items, onSelected: onSelected, height: height);
  }

  static Widget _iosLegacyButton<T>({
    required String label,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected,
    required double height,
  }) {
    return Builder(
      builder: (context) => SizedBox(
        height: height,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          onPressed: () => _showMenu<T>(context, label, items, onSelected),
          child: Text(label),
        ),
      ),
    );
  }

  /// Creates a popup menu button with a custom child widget
  static Widget widget<T>({
    Key? key,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry)
    onSelected,
    Color? tint,
    PopupButtonStyle buttonStyle = PopupButtonStyle.plain,
    bool triggerOnLongPress = false,
    VoidCallback? onTap,
    required Widget child,
  }) {
    assert(
      onTap == null || triggerOnLongPress,
      'onTap is only used with triggerOnLongPress: true (tap fires onTap, '
      'long-press opens the menu).',
    );
    if (PlatformInfo.isMacOS) {
      return _MacOSPopupMenuButton<T>.widget(
        items: items,
        onSelected: onSelected,
        triggerOnLongPress: triggerOnLongPress,
        onTap: onTap,
        child: child,
      );
    }

    // iOS 26+ - Use gesture detector with native menu
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26PopupMenuButton<T>.widget(
        items: items,
        onSelected: onSelected,
        tint: tint,
        buttonStyle: buttonStyle,
        triggerOnLongPress: triggerOnLongPress,
        onTap: onTap,
        child: child,
      );
    }

    // Android - Use Material PopupMenuButton with custom child
    if (PlatformInfo.isAndroid) {
      return _MaterialPopupMenuButton<T>.widget(
        items: items,
        onSelected: onSelected,
        tint: tint,
        child: child,
      );
    }

    // iOS <26 (iOS 18 and below) - Use GestureDetector with action sheet
    return _iosLegacyWidget<T>(items: items, onSelected: onSelected, triggerOnLongPress: triggerOnLongPress, onTap: onTap, child: child);
  }

  static Widget _iosLegacyWidget<T>({
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected,
    required bool triggerOnLongPress,
    VoidCallback? onTap,
    required Widget child,
  }) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: triggerOnLongPress ? onTap : () => _showMenu<T>(context, null, items, onSelected),
        onLongPress: triggerOnLongPress ? () => _showMenu<T>(context, null, items, onSelected) : null,
        child: child,
      ),
    );
  }

  /// Creates a round, icon-only popup menu button
  ///
  /// [icon] can be either:
  /// - String (SF Symbol) for iOS 26+
  /// - IconData for iOS <26 and Android
  static Widget icon<T>({
    Key? key,
    required dynamic icon,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry)
    onSelected,
    Color? tint,
    double size = 44.0,
    PopupButtonStyle buttonStyle = PopupButtonStyle.glass,
  }) {
    if (PlatformInfo.isMacOS) {
      return _MacOSPopupMenuButton<T>.icon(
        icon: icon,
        items: items,
        onSelected: onSelected,
        tint: tint,
        size: size,
      );
    }

    // iOS 26+ - Use native iOS 26 popup menu button (expects String - SF Symbol)
    if (PlatformInfo.isIOS26OrHigher()) {
      return IOS26PopupMenuButton<T>.icon(
        buttonIcon: icon is String ? icon : 'ellipsis.circle',
        items: items,
        onSelected: onSelected,
        tint: tint,
        size: size,
        buttonStyle: buttonStyle,
      );
    }

    // Android - Use Material IconButton with PopupMenu
    if (PlatformInfo.isAndroid) {
      return _MaterialPopupMenuButton<T>.icon(
        icon: icon,
        items: items,
        onSelected: onSelected,
        tint: tint,
        size: size,
      );
    }

    // iOS <26 (iOS 18 and below) - Use icon button with action sheet (iOS fallback)
    return _iosLegacyIcon<T>(icon: icon, items: items, onSelected: onSelected, size: size);
  }

  static Widget _iosLegacyIcon<T>({
    required dynamic icon,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected,
    required double size,
    Color? tint,
  }) {
    return Builder(
      builder: (context) => SizedBox(
        width: size,
        height: size,
        child: CupertinoButton(
          padding: const EdgeInsets.all(4),
          onPressed: () => _showMenu<T>(context, null, items, onSelected),
          child: Icon(
            icon is IconData ? icon : sfSymbolToCupertinoIcon(icon is String ? icon : 'ellipsis.circle'),
            size: size * 0.55,
            color: tint,
          ),
        ),
      ),
    );
  }

  static Widget _buildActionSheetContent<T>(AdaptivePopupMenuItem<T> item) {
    final hasImage = item.imageBytes != null;
    final hasSubtitle = item.subtitle != null && item.subtitle!.isNotEmpty;

    if (!hasImage && !hasSubtitle) {
      if (!item.selected) return Text(item.label);
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.checkmark, size: 18),
          const SizedBox(width: 8),
          Text(item.label),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (item.selected) ...[
          const Icon(CupertinoIcons.checkmark, size: 18),
          const SizedBox(width: 8),
        ],
        if (hasImage) ...[
          ClipOval(
            child: Image.memory(
              item.imageBytes!,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              hasImage ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Text(item.label),
            if (hasSubtitle)
              Text(
                item.subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
          ],
        ),
      ],
    );
  }

  static Future<void> _showMenu<T>(
    BuildContext context,
    String? title,
    List<AdaptivePopupMenuEntry> items,
    void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected,
  ) async {
    final selected = await showCupertinoModalPopup<int>(
      context: context,
      builder: (ctx) {
        return CupertinoActionSheet(
          title: title != null ? Text(title) : null,
          actions: [
            for (var i = 0; i < items.length; i++)
              if (items[i] is AdaptivePopupMenuItem<T>)
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.of(ctx).pop(i),
                  isDestructiveAction: (items[i] as AdaptivePopupMenuItem<T>).isDestructive,
                  child: _buildActionSheetContent<T>(
                    items[i] as AdaptivePopupMenuItem<T>,
                  ),
                )
              else
                const SizedBox(height: 8),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            isDefaultAction: true,
            child: Text(
              PlatformInfo.isCupertino
                  ? CupertinoLocalizations.of(ctx).cancelButtonLabel
                  : MaterialLocalizations.of(ctx).cancelButtonLabel,
            ),
          ),
        );
      },
    );

    if (selected != null) {
      final selectedEntry = items[selected];
      if (selectedEntry is AdaptivePopupMenuItem<T>) {
        onSelected(selected, selectedEntry);
      }
    }
  }
}

/// Material implementation of popup menu button for Android
class _MaterialPopupMenuButton<T> extends StatefulWidget {
  const _MaterialPopupMenuButton({
    required this.label,
    required this.items,
    required this.onSelected,
    this.tint,
    this.height = 32.0,
  }) : icon = null,
       size = null,
       child = null;

  const _MaterialPopupMenuButton.icon({
    required this.icon,
    required this.items,
    required this.onSelected,
    this.tint,
    this.size = 44.0,
  }) : label = null,
       height = null,
       child = null;

  const _MaterialPopupMenuButton.widget({
    required this.items,
    required this.onSelected,
    this.tint,
    required this.child,
  }) : label = null,
       icon = null,
       height = null,
       size = null;

  final String? label;
  final dynamic icon; // IconData for Android
  final Widget? child;
  final List<AdaptivePopupMenuEntry> items;
  final void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected;
  final Color? tint;
  final double? height;
  final double? size;

  bool get isIconButton => icon != null;
  bool get isCustomWidget => child != null;

  @override
  State<_MaterialPopupMenuButton<T>> createState() =>
      _MaterialPopupMenuButtonState<T>();
}

class _MaterialPopupMenuButtonState<T>
    extends State<_MaterialPopupMenuButton<T>> {
  @override
  Widget build(BuildContext context) {
    final menuItems = <PopupMenuEntry<int>>[];

    for (var i = 0; i < widget.items.length; i++) {
      if (widget.items[i] is AdaptivePopupMenuDivider) {
        menuItems.add(const PopupMenuDivider());
      } else if (widget.items[i] is AdaptivePopupMenuItem<T>) {
        final item = widget.items[i] as AdaptivePopupMenuItem<T>;
        final labelStyle = item.isDestructive
            ? TextStyle(color: Theme.of(context).colorScheme.error)
            : null;
        final hasSubtitle = item.subtitle != null && item.subtitle!.isNotEmpty;
        menuItems.add(
          PopupMenuItem<int>(
            value: i,
            enabled: item.enabled,
            child: Row(
              children: [
                if (item.imageBytes != null) ...[
                  ClipOval(
                    child: Image.memory(
                      item.imageBytes!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else if (item.icon != null) ...[
                  Icon(
                    item.icon is IconData
                        ? item.icon as IconData
                        : Icons.circle,
                    size: 20,
                    color: item.isDestructive
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: hasSubtitle
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.label, style: labelStyle),
                            Text(
                              item.subtitle!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        )
                      : Text(item.label, style: labelStyle),
                ),
                if (item.selected) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.check,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        );
      }
    }

    // Custom widget case
    if (widget.isCustomWidget) {
      return PopupMenuButton<int>(
        child: widget.child!,
        itemBuilder: (context) => menuItems,
        onSelected: (index) {
          final selectedEntry = widget.items[index];
          if (selectedEntry is AdaptivePopupMenuItem<T>) {
            widget.onSelected(index, selectedEntry);
          }
        },
      );
    }

    if (widget.isIconButton) {
      // Match iOS legacy: size * 0.55 glyph in a size×size box.
      // Do NOT pass [constraints] here — on PopupMenuButton that sizes the
      // menu panel, not the IconButton (and a 28px menu overflows its Row).
      final double side = widget.size ?? 44.0;
      final double iconSize = side * 0.55;
      return SizedBox(
        width: side,
        height: side,
        child: PopupMenuButton<int>(
          padding: EdgeInsets.zero,
          iconSize: iconSize,
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size(side, side),
            fixedSize: Size(side, side),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            alignment: Alignment.center,
          ),
          icon: Icon(
            widget.icon is IconData ? widget.icon as IconData : Icons.more_vert,
            size: iconSize,
            color: widget.tint,
          ),
          itemBuilder: (context) => menuItems,
          onSelected: (index) {
            final selectedEntry = widget.items[index];
            if (selectedEntry is AdaptivePopupMenuItem<T>) {
              widget.onSelected(index, selectedEntry);
            }
          },
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: TextButton(
        onPressed: () {},
        child: PopupMenuButton<int>(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label ?? ''),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
          itemBuilder: (context) => menuItems,
          onSelected: (index) {
            final selectedEntry = widget.items[index];
            if (selectedEntry is AdaptivePopupMenuItem<T>) {
              widget.onSelected(index, selectedEntry);
            }
          },
        ),
      ),
    );
  }
}

class _MacOSPopupMenuButton<T> extends StatelessWidget {
  const _MacOSPopupMenuButton({
    required this.items,
    required this.onSelected,
    this.label,
    this.height = 32,
  }) : icon = null,
       size = 44,
       child = null,
       triggerOnLongPress = false,
       onTap = null,
       tint = null;

  const _MacOSPopupMenuButton.icon({
    required this.icon,
    required this.items,
    required this.onSelected,
    this.tint,
    this.size = 44,
  }) : label = null,
       height = 32,
       child = null,
       triggerOnLongPress = false,
       onTap = null;

  const _MacOSPopupMenuButton.widget({
    required this.items,
    required this.onSelected,
    required this.child,
    this.triggerOnLongPress = false,
    this.onTap,
  }) : label = null,
       icon = null,
       tint = null,
       height = 32,
       size = 44;

  final String? label;
  final dynamic icon;
  final Widget? child;
  final double height;
  final double size;
  final Color? tint;
  final bool triggerOnLongPress;
  final VoidCallback? onTap;
  final List<AdaptivePopupMenuEntry> items;
  final void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected;

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final flutterView = View.of(context);
    final viewSize = flutterView.physicalSize / flutterView.devicePixelRatio;
    int? selected;
    try {
      selected = await MacOSControls.showMenu(
        x: origin.dx,
        y: origin.dy,
        width: box.size.width,
        height: box.size.height,
        viewWidth: viewSize.width,
        viewHeight: viewSize.height,
        items: items,
      );
    } on MissingPluginException {
      if (!context.mounted) return;
      await AdaptivePopupMenuButton._showMenu<T>(context, label, items, onSelected);
      return;
    }
    if (selected == null) return;
    final entry = items[selected];
    if (entry is AdaptivePopupMenuItem<T>) {
      onSelected(selected, entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget trigger;
    if (child != null) {
      trigger = child!;
    } else if (icon != null) {
      trigger = SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon is IconData
              ? icon as IconData
              : sfSymbolToCupertinoIcon(icon is String ? icon : 'ellipsis.circle'),
          size: size * 0.55,
          color: tint,
        ),
      );
    } else {
      trigger = SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(label ?? ''),
          ),
        ),
      );
    }

    return Builder(
      builder: (buttonContext) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: triggerOnLongPress ? onTap : () => _open(buttonContext),
        onLongPress: triggerOnLongPress ? () => _open(buttonContext) : null,
        child: trigger,
      ),
    );
  }
}
