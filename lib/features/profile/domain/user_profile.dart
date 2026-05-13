import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// The authenticated user's profile and dietary preferences.
///
/// [dietaryRestrictions] holds user-defined restrictions (e.g. 'gluten-free',
/// 'vegan'). [primaryGoal] represents their nutritional objective.
/// [groceryBudget] is nullable until the user configures a budget.
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
    @Default([]) List<String> dietaryRestrictions,
    String? primaryGoal,
    double? groceryBudget,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
