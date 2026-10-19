import 'package:flutter/material.dart';
import 'package:table_pagination/src/models/table_action.dart';

/// Renders the shared foreground treatment for row-action menus.
class TableActionMenuItem<T> extends StatelessWidget {
  const TableActionMenuItem({
    super.key,
    required this.action,
    required this.brightness,
    required this.isEnabled,
  });

  final TableAction<T> action;
  final Brightness brightness;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final effectiveColor = isEnabled
        ? foregroundColor
        : foregroundColor.withValues(alpha: 0.38);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: FittedBox(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
              child: action.icon,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            action.name,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: effectiveColor),
          ),
        ),
      ],
    );
  }
}
