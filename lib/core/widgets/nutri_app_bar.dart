import 'package:flutter/material.dart';

/// Reusable [AppBar] for all NutriGuide screens.
///
/// Consumes theme tokens via [Theme.of(context)] — no hardcoded colors.
///
/// Usage:
/// ```dart
/// Scaffold(
///   appBar: NutriAppBar(title: 'Home'),
/// )
/// ```
class NutriAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NutriAppBar({
    required this.title,
    super.key,
    this.actions,
    this.leading,
    this.centerTitle = false,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      title: Text(
        title,
        style: textTheme.titleLarge,
      ),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
