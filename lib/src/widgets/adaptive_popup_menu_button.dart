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
    return Builder(
      builder: (context) => GestureDetector(
        onTap: triggerOnLongPress
            ? onTap
            : () => _showMenu<T>(context, null, items, onSelected),
        onLongPress: triggerOnLongPress
            ? () => _showMenu<T>(context, null, items, onSelected)
            : null,
        child: child,
      ),
    );
  }

  /// Creates a round, icon-only popup menu button
  ///
  /// [icon] can be either:
  /// - String (SF Symbol) for iOS 26+
  /// - IconData for iOS <26 and Android
  /// [iconSize] is the glyph's point size on every platform; the button
  /// itself stays [size] wide and tall.
  static Widget icon<T>({
    Key? key,
    required dynamic icon,
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry)
    onSelected,
    Color? tint,
    double size = 44.0,
    double? iconSize,
    PopupButtonStyle buttonStyle = PopupButtonStyle.glass,
  }) {
    if (PlatformInfo.isMacOS) {
      return _MacOSPopupMenuButton<T>.icon(
        icon: icon,
        items: items,
        onSelected: onSelected,
        tint: tint,
        size: size,
        iconSize: iconSize,
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
        iconSize: iconSize,
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
        iconSize: iconSize,
      );
    }

    // iOS <26 (iOS 18 and below) - Use icon button with action sheet (iOS fallback)
    return Builder(
      builder: (context) => SizedBox(
        width: size,
        height: size,
        child: CupertinoButton(
          padding: const EdgeInsets.all(4),
          onPressed: () => _showMenu<T>(context, null, items, onSelected),
          child: Icon(
            icon is IconData ? icon : sfSymbolToCupertinoIcon(icon is String ? icon : 'ellipsis.circle'),
            size: iconSize ?? size * 0.55,
            color: tint,
          ),
        ),
      ),
    );
  }

  /// Opens [items] for a button drawn elsewhere, such as an app bar action:
  /// an action sheet on iOS, a popup menu at [context]'s button otherwise.
  /// Buttons above the navigator pass the page's [navigator].
  static Future<void> show<T>(
    BuildContext context, {
    required List<AdaptivePopupMenuEntry> items,
    required void Function(int index, AdaptivePopupMenuItem<T> entry)
    onSelected,
    NavigatorState? navigator,
  }) async {
    final menuContext =
        (navigator ?? Navigator.maybeOf(context))?.overlay?.context;
    if (menuContext == null) return;
    if (PlatformInfo.isMacOS) {
      return _showMacOSMenu<T>(context, items, onSelected, fallbackContext: menuContext);
    }
    if (PlatformInfo.isCupertino) {
      return _showMenu<T>(menuContext, null, items, onSelected);
    }
    final button = context.findRenderObject() as RenderBox?;
    final overlay = menuContext.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;
    // Global coordinates, as the button may sit in a bar above the navigator
    final topLeft = overlay.globalToLocal(button.localToGlobal(Offset.zero));
    final selected = await showMenu<int>(
      context: menuContext,
      position: RelativeRect.fromRect(
        topLeft & button.size,
        Offset.zero & overlay.size,
      ),
      items: _materialMenuItems<T>(menuContext, items),
    );
    if (selected != null && items[selected] is AdaptivePopupMenuItem<T>) {
      onSelected(selected, items[selected] as AdaptivePopupMenuItem<T>);
    }
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
          crossAxisAlignment: hasImage
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
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

  static List<PopupMenuEntry<int>> _materialMenuItems<T>(
    BuildContext context,
    List<AdaptivePopupMenuEntry> items,
  ) {
    final menuItems = <PopupMenuEntry<int>>[];

    for (var i = 0; i < items.length; i++) {
      if (items[i] is AdaptivePopupMenuDivider) {
        menuItems.addAll(_materialDivider(context, items[i], i));
      } else if (items[i] is AdaptivePopupMenuItem<T>) {
        final item = items[i] as AdaptivePopupMenuItem<T>;
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
                              style: Theme.of(context).textTheme.bodySmall
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
    return menuItems;
  }

  /// Opens [items] as a native AppKit menu at [buttonContext]'s button, or as
  /// the action sheet when the macOS plugin isn't registered.
  static Future<void> _showMacOSMenu<T>(
    BuildContext buttonContext,
    List<AdaptivePopupMenuEntry> items,
    void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected, {
    String? title,
    BuildContext? fallbackContext,
  }) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final flutterView = View.of(buttonContext);
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
      final context = fallbackContext ?? buttonContext;
      if (!context.mounted) return;
      return _showMenu<T>(context, title, items, onSelected);
    }
    if (selected == null) return;
    final entry = items[selected];
    if (entry is AdaptivePopupMenuItem<T>) {
      onSelected(selected, entry);
    }
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
                  isDestructiveAction:
                      (items[i] as AdaptivePopupMenuItem<T>).isDestructive,
                  child: _buildActionSheetContent<T>(
                    items[i] as AdaptivePopupMenuItem<T>,
                  ),
                )
              else
                _buildSheetDivider(ctx, items[i]),
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

  /// The gap between two groups in the action sheet, carrying the group's
  /// title when the divider has one; the sheet has no section of its own.
  static Widget _buildSheetDivider(
    BuildContext context,
    AdaptivePopupMenuEntry entry,
  ) {
    final title = entry is AdaptivePopupMenuDivider ? entry.title : null;
    if (title == null || title.isEmpty) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ),
    );
  }

  /// A Material divider, preceded by nothing for the first group and followed
  /// by a disabled heading row when the divider carries a title.
  static List<PopupMenuEntry<int>> _materialDivider(
    BuildContext context,
    AdaptivePopupMenuEntry entry,
    int index,
  ) {
    final title = entry is AdaptivePopupMenuDivider ? entry.title : null;
    return [
      if (index > 0) const PopupMenuDivider(),
      if (title != null && title.isNotEmpty)
        PopupMenuItem<int>(
          enabled: false,
          height: 32,
          child: Text(title, style: Theme.of(context).textTheme.labelMedium),
        ),
    ];
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
       iconSize = null,
       child = null;

  const _MaterialPopupMenuButton.icon({
    required this.icon,
    required this.items,
    required this.onSelected,
    this.tint,
    this.size = 44.0,
    this.iconSize,
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
       size = null,
       iconSize = null;

  final String? label;
  final dynamic icon; // IconData for Android
  final Widget? child;
  final List<AdaptivePopupMenuEntry> items;
  final void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected;
  final Color? tint;
  final double? height;
  final double? size;
  final double? iconSize;

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
    final menuItems = AdaptivePopupMenuButton._materialMenuItems<T>(
      context,
      widget.items,
    );

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
      final double iconSize = widget.iconSize ?? side * 0.55;
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
            color: widget.tint,
            size: iconSize,
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
       iconSize = null,
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
    this.iconSize,
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
       size = 44,
       iconSize = null;

  final String? label;
  final dynamic icon;
  final Widget? child;
  final double height;
  final double size;
  final double? iconSize;
  final Color? tint;
  final bool triggerOnLongPress;
  final VoidCallback? onTap;
  final List<AdaptivePopupMenuEntry> items;
  final void Function(int index, AdaptivePopupMenuItem<T> entry) onSelected;

  Future<void> _open(BuildContext context) =>
      AdaptivePopupMenuButton._showMacOSMenu<T>(context, items, onSelected, title: label);

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
          size: iconSize ?? size * 0.55,
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
