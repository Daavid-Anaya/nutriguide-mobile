import 'package:freezed_annotation/freezed_annotation.dart';

part 'wellness_summary.freezed.dart';
part 'wellness_summary.g.dart';

/// A summary of the user's wellness metrics for the current period.
///
/// Displayed on the Home screen as the primary health dashboard.
@freezed
abstract class WellnessSummary with _$WellnessSummary {
  const factory WellnessSummary({
    required int healthScore,
    required int streak,
    required double budgetSpent,
    required double budgetTotal,
  }) = _WellnessSummary;

  factory WellnessSummary.fromJson(Map<String, dynamic> json) =>
      _$WellnessSummaryFromJson(json);
}
