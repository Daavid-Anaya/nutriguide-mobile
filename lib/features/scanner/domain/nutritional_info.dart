import 'package:freezed_annotation/freezed_annotation.dart';

part 'nutritional_info.freezed.dart';
part 'nutritional_info.g.dart';

/// Nutritional values from Open Food Facts API.
///
/// All fields are nullable because Open Food Facts data can be incomplete —
/// products may have some nutritional values missing or not yet entered.
/// Values are per 100g/100ml unless the API specifies otherwise.
@freezed
abstract class NutritionalInfo with _$NutritionalInfo {
  const factory NutritionalInfo({
    double? energy,
    double? fat,
    double? saturatedFat,
    double? carbohydrates,
    double? sugars,
    double? proteins,
    double? salt,
    double? fiber,
  }) = _NutritionalInfo;

  factory NutritionalInfo.fromJson(Map<String, dynamic> json) =>
      _$NutritionalInfoFromJson(json);
}
