// Design: AD-60 — avatarUploadServiceProvider
// TDD: T-06 [GREEN] — Provider for AvatarUploadService

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/supabase/supabase_providers.dart';
import 'package:nutriguide_mobile/features/profile/data/avatar_upload_service.dart';

/// Provides the [AvatarUploadService] singleton.
///
/// Overridable in tests via [ProviderContainer] to inject a mock.
final avatarUploadServiceProvider = Provider<AvatarUploadService>((ref) {
  return AvatarUploadService(
    supabaseClient: ref.read(supabaseClientProvider),
  );
});
