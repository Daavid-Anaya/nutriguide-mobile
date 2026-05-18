// Spec: PROFILE-STATE-001, AVATAR-NOTIFIER-001
// Design: AD-38 (6 sealed variants), AD-39 (AsyncNotifier pattern), AD-61
// TDD: T-08 [GREEN] — Added ProfileUploading + updateAvatar()

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/supabase/supabase_providers.dart';
import 'package:nutriguide_mobile/features/profile/data/avatar_upload_providers.dart';
import 'package:nutriguide_mobile/features/profile/data/avatar_upload_service.dart';
import 'package:nutriguide_mobile/features/profile/data/profile_providers.dart';
import 'package:nutriguide_mobile/features/profile/domain/profile_repository.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';

// ---------------------------------------------------------------------------
// Sealed State — 6 variants (AD-38 + ProfileUploading for AVATAR-NOTIFIER-001)
// ---------------------------------------------------------------------------
sealed class ProfileState {
  const ProfileState();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileData extends ProfileState {
  const ProfileData({required this.profile});
  final UserProfile profile;
}

class ProfileEditing extends ProfileState {
  const ProfileEditing({required this.profile});
  final UserProfile profile;
}

class ProfileSaving extends ProfileState {
  const ProfileSaving({required this.profile});
  final UserProfile profile;
}

class ProfileUploading extends ProfileState {
  const ProfileUploading({required this.profile});
  final UserProfile profile;
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class ProfileNotifier extends AsyncNotifier<ProfileState> {
  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  @override
  Future<ProfileState> build() async {
    final result = await _repo.getProfile();
    return result.fold(
      (failure) => ProfileError(failure.message),
      (profile) => ProfileData(profile: profile),
    );
  }

  void startEdit() {
    if (state case AsyncData(value: ProfileData(:final profile))) {
      state = AsyncData(ProfileEditing(profile: profile));
    }
  }

  void cancelEdit() {
    if (state case AsyncData(value: ProfileEditing(:final profile))) {
      state = AsyncData(ProfileData(profile: profile));
    }
  }

  Future<void> saveProfile(
    String name,
    String? avatarUrl,
    double? groceryBudget,
  ) async {
    if (name.trim().isEmpty) return;
    if (groceryBudget != null && groceryBudget <= 0) return;

    if (state case AsyncData(value: ProfileEditing(:final profile))) {
      final trimmedUrl = avatarUrl?.trim();
      final updated = profile.copyWith(
        name: name.trim(),
        avatarUrl: (trimmedUrl == null || trimmedUrl.isEmpty) ? null : trimmedUrl,
        groceryBudget: groceryBudget,
      );
      state = AsyncData(ProfileSaving(profile: updated));
      final result = await _repo.updateProfile(updated);
      state = result.fold(
        (failure) => AsyncData(ProfileError(failure.message)),
        (_) => AsyncData(ProfileData(profile: updated)),
      );
    }
  }

  /// Orchestrates avatar pick → upload → save flow (AVATAR-NOTIFIER-001).
  ///
  /// Guard: only executes from [ProfileData] state (AD-61).
  /// On success: calls [saveProfile] with new avatarUrl.
  /// On [AvatarUploadCancelled]: silently returns to [ProfileData].
  /// On [AvatarUploadFailed]: transitions to [ProfileError].
  Future<void> updateAvatar() async {
    // Guard: only from ProfileData (AVATAR-NOTIFIER-001-S4)
    final currentState = state.value;
    if (currentState is! ProfileData) return;

    final profile = currentState.profile;
    state = AsyncData(ProfileUploading(profile: profile));

    final userId = ref.read(supabaseClientProvider).auth.currentUser!.id;
    final uploadService = ref.read(avatarUploadServiceProvider);

    try {
      final newUrl = await uploadService.pickAndUpload(userId);

      // Transition to Editing to reuse the existing saveProfile flow
      state = AsyncData(ProfileEditing(profile: profile));
      await saveProfile(
        profile.name,
        newUrl,
        profile.groceryBudget,
      );
    } on AvatarUploadCancelled {
      // User cancelled — return to data view silently (AVATAR-NOTIFIER-001-S2)
      state = AsyncData(ProfileData(profile: profile));
    } on AvatarUploadFailed {
      // Upload failed — show user-friendly error (AVATAR-NOTIFIER-001-S3)
      state = AsyncData(const ProfileError('No se pudo subir la imagen'));
    }
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
