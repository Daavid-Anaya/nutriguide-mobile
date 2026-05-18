import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/profile/domain/profile_repository.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';

/// Supabase-backed implementation of [ProfileRepository].
///
/// Read pattern: Supabase primary → SharedPreferences write-through cache.
/// Fallback: SharedPreferences when unauthenticated or on Supabase error.
///
/// Spec: PROFILE-SYNC-001 | Design: AD-51.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required SharedPreferences sharedPreferences,
    required SupabaseClient supabaseClient,
  })  : _prefs = sharedPreferences,
        _supabase = supabaseClient;

  final SharedPreferences _prefs;
  final SupabaseClient _supabase;

  // SharedPreferences keys
  static const _keyName = 'user_name';
  static const _keyAvatar = 'user_avatar_url';
  static const _keyBudget = 'grocery_budget';

  User? get _currentUser => _supabase.auth.currentUser;

  @override
  Future<Either<Failure, UserProfile>> getProfile() async {
    final user = _currentUser;

    // Unauthenticated: return local data (AD-56)
    if (user == null) {
      return Right(_readLocalProfile(id: '', email: ''));
    }

    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      final profile = _mapToUserProfile(response, user);
      _writeLocalCache(profile);
      return Right(profile);
    } catch (_) {
      // Fall back to local cache on any Supabase error (AD-51)
      return Right(_readLocalProfile(
        id: user.id,
        email: user.email ?? '',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile(UserProfile profile) async {
    // Always update local cache first
    _writeLocalCache(profile);

    final user = _currentUser;

    // Unauthenticated: local only (AD-56)
    if (user == null) {
      return const Right(null);
    }

    try {
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'name': profile.name,
        'email': user.email ?? '',
        'avatar_url': profile.avatarUrl,
        'dietary_restrictions': profile.dietaryRestrictions,
        'primary_goal': profile.primaryGoal,
        'grocery_budget': profile.groceryBudget,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure('Failed to update profile: $e'));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  UserProfile _readLocalProfile({
    required String id,
    required String email,
  }) {
    return UserProfile(
      id: id,
      name: _prefs.getString(_keyName) ?? 'Usuario',
      email: email,
      avatarUrl: _prefs.getString(_keyAvatar),
      groceryBudget: _prefs.getDouble(_keyBudget),
    );
  }

  UserProfile _mapToUserProfile(
    Map<String, dynamic> row,
    User user,
  ) {
    return UserProfile(
      id: user.id,
      name: (row['name'] as String?) ?? 'Usuario',
      email: user.email ?? '',
      avatarUrl: row['avatar_url'] as String?,
      dietaryRestrictions:
          (row['dietary_restrictions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      primaryGoal: row['primary_goal'] as String?,
      groceryBudget: (row['grocery_budget'] as num?)?.toDouble(),
    );
  }

  void _writeLocalCache(UserProfile profile) {
    _prefs.setString(_keyName, profile.name);
    if (profile.avatarUrl != null) {
      _prefs.setString(_keyAvatar, profile.avatarUrl!);
    } else {
      _prefs.remove(_keyAvatar);
    }
    if (profile.groceryBudget != null) {
      _prefs.setDouble(_keyBudget, profile.groceryBudget!);
    } else {
      _prefs.remove(_keyBudget);
    }
  }
}
