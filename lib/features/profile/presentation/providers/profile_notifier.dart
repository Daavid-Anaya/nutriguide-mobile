// Spec: PROFILE-STATE-001
// Design: AD-38 (5 sealed variants), AD-39 (AsyncNotifier pattern)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/features/profile/data/profile_providers.dart';
import 'package:nutriguide_mobile/features/profile/domain/profile_repository.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';

// ---------------------------------------------------------------------------
// Sealed State — 5 variants (AD-38)
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
