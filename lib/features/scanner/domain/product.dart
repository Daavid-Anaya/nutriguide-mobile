import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nutriguide_mobile/features/scanner/domain/nutritional_info.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// A scanned product from the Open Food Facts database.
///
/// [id] is nullable because some products may not have an assigned OFF id.
/// [nutriments] is nullable because not all products have nutritional data.
@freezed
abstract class Product with _$Product {
  const factory Product({
    String? id,
    required String barcode,
    required String name,
    String? brands,
    String? imageUrl,
    String? nutriscoreGrade,
    NutritionalInfo? nutriments,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
