import 'package:freezed_annotation/freezed_annotation.dart';

part 'shopping_item.freezed.dart';
part 'shopping_item.g.dart';

/// A single item within a [ShoppingList].
///
/// [quantity] and [unit] are nullable — some items (e.g. "milk") may not
/// have a measurable quantity. [estimatedPrice] is nullable until the user
/// sets it. [productBarcode] links the item to a scanned product, if any.
@freezed
abstract class ShoppingItem with _$ShoppingItem {
  const factory ShoppingItem({
    required String id,
    required String name,
    double? quantity,
    String? unit,
    double? estimatedPrice,
    @Default(false) bool isChecked,
    String? productBarcode,
  }) = _ShoppingItem;

  factory ShoppingItem.fromJson(Map<String, dynamic> json) =>
      _$ShoppingItemFromJson(json);
}
