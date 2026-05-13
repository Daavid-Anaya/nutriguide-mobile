import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';

part 'shopping_list.freezed.dart';
part 'shopping_list.g.dart';

/// A user-created shopping list containing [ShoppingItem]s.
///
/// Supports offline-first updates — changes are persisted locally first,
/// then synced to the backend when connectivity is available.
@freezed
abstract class ShoppingList with _$ShoppingList {
  const factory ShoppingList({
    required String id,
    required String name,
    @Default([]) List<ShoppingItem> items,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ShoppingList;

  factory ShoppingList.fromJson(Map<String, dynamic> json) =>
      _$ShoppingListFromJson(json);
}
