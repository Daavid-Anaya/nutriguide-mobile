// Spec: HOME-UI-002 sc1–sc4
// Design: AD-32 — CachedNetworkImage + Icon(Icons.person) fallback in CircleAvatar. No bell icon (AD-30).
// Design: AD-42 — Optional onTap callback wraps avatar in GestureDetector for profile navigation.
// TDD: T-08 [GREEN] — Implements HomeHeader to pass T-07 tests.
// TDD: T-16 [GREEN] — Adds VoidCallback? onTap to pass T-15 tests.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nutriguide_mobile/core/extensions/context_extensions.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';

/// Top header row for the Home screen.
///
/// Renders a [CircleAvatar] with [CachedNetworkImage] when [avatarUrl] is
/// non-null, falling back to [Icon(Icons.person)] on null or load error.
/// Displays the "NutriGuide" brand text in [titleLarge] style.
///
/// No notification bell icon (AD-30).
///
/// Spec: HOME-UI-002 | Design: AD-32.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.avatarUrl,
    this.onTap,
  });

  /// The user's avatar URL. When null, shows [Icons.person] fallback.
  final String? avatarUrl;

  /// Optional tap callback. When non-null, the avatar is wrapped in a
  /// [GestureDetector] — typically used to navigate to the profile screen.
  ///
  /// Design: AD-42 — pure widget; the screen injects the callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget avatar = _buildAvatar(context);
    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }
    return Row(
      children: [
        avatar,
        const SizedBox(width: AppSpacing.md),
        Text(
          'NutriGuide',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colorScheme.primary,
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (avatarUrl != null) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: context.colorScheme.primaryContainer,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl!,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorWidget: (ctx, url, err) => _personIcon(ctx),
            placeholder: (ctx, url) => _personIcon(ctx),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: context.colorScheme.primaryContainer,
      child: _personIcon(context),
    );
  }

  Widget _personIcon(BuildContext context) {
    return Icon(
      Icons.person,
      size: 24,
      color: context.colorScheme.onPrimaryContainer,
    );
  }
}
