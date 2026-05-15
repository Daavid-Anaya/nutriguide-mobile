// Spec: HOME-UI-002 sc1–sc4
// Design: AD-32 — CachedNetworkImage + Icon(Icons.person) fallback in CircleAvatar. No bell icon (AD-30).
// TDD: T-08 [GREEN] — Implements HomeHeader to pass T-07 tests.

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
  });

  /// The user's avatar URL. When null, shows [Icons.person] fallback.
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildAvatar(context),
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
