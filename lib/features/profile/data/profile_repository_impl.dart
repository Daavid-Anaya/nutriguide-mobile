import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutriguide_mobile/core/error/failure.dart';
import 'package:nutriguide_mobile/features/profile/domain/profile_repository.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';

/// SharedPreferences-backed implementation of [ProfileRepository].
///
/// Stores two keys: [_keyName] (`user_name`) and [_keyAvatar] (`user_avatar_url`).
/// When a key is absent, [getProfile] returns safe defaults:
/// - `name` → `"Usuario"`
/// - `avatarUrl` → `null`
///
/// All errors are wrapped in [Left(CacheFailure())].
/// Spec: PROFILE-DATA-001 | Design: AD-27.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences;

  final SharedPreferences _prefs;

  static const _keyName = 'user_name';
  static const _keyAvatar = 'user_avatar_url';
  static const _keyBudget = 'grocery_budget';

  @override
  Future<Either<Failure, UserProfile>> getProfile() async {
    try {
      return Right(UserProfile(
        id: '',
        name: _prefs.getString(_keyName) ?? 'Usuario',
        email: '',
        avatarUrl: _prefs.getString(_keyAvatar),
        groceryBudget: _prefs.getDouble(_keyBudget),
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile(UserProfile profile) async {
    try {
      await _prefs.setString(_keyName, profile.name);
      if (profile.avatarUrl != null) {
        await _prefs.setString(_keyAvatar, profile.avatarUrl!);
      } else {
        await _prefs.remove(_keyAvatar);
      }
      if (profile.groceryBudget != null) {
        await _prefs.setDouble(_keyBudget, profile.groceryBudget!);
      } else {
        await _prefs.remove(_keyBudget);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
