// Spec: PROFILE-UI-003
// Design: AD-38 — ProfileAvatar with CachedNetworkImage + Icon(Icons.person) fallback
// TDD: T-08 [GREEN] — Implements ProfileAvatar to pass T-07 tests.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Circular avatar widget for the profile feature.
///
/// Renders a [CachedNetworkImage] inside a [CircleAvatar] when [avatarUrl] is
/// non-null and non-empty, falling back to [Icon(Icons.person)] otherwise.
///
/// Spec: PROFILE-UI-003 | Design: AD-38.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.avatarUrl, this.radius = 48});

  /// The user's avatar URL. When null or empty, shows [Icons.person] fallback.
  final String? avatarUrl;

  /// Radius of the circle in logical pixels. Default is 48 (96dp diameter).
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            width: radius * 2,
            height: radius * 2,
            errorWidget: (context, url, error) => Icon(Icons.person, size: radius),
            placeholder: (context, url) => Icon(Icons.person, size: radius),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      child: Icon(Icons.person, size: radius),
    );
  }
}
