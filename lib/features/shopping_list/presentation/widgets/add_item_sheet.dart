// Spec: SHOPPING-LIST-003 | Design: AD-23
// TDD: T-4.6 [GREEN] — Implements AddItemSheet to pass add_item_sheet_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nutriguide_mobile/core/theme/app_spacing.dart';
import 'package:nutriguide_mobile/features/shopping_list/domain/shopping_item.dart';
import 'package:nutriguide_mobile/features/shopping_list/presentation/providers/shopping_list_notifier.dart';

/// Modal bottom sheet form for adding a new item to the shopping list.
///
/// Uses [HookConsumerWidget] for auto-disposing [TextEditingController]s.
/// Name field is required; quantity, unit, and estimatedPrice are optional.
///
/// On valid submission:
/// 1. Builds a [ShoppingItem] from the form values.
/// 2. Calls [ShoppingListNotifier.addItem].
/// 3. Pops the sheet.
///
/// Spec: SHOPPING-LIST-003 | Design: AD-23.
class AddItemSheet extends HookConsumerWidget {
  const AddItemSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameCtrl = useTextEditingController();
    final quantityCtrl = useTextEditingController();
    final unitCtrl = useTextEditingController();
    final priceCtrl = useTextEditingController();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.lg,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Agregar producto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),

            // Name — required
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Quantity + Unit row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: quantityCtrl,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: unitCtrl,
                    decoration: const InputDecoration(labelText: 'Unidad'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Estimated price — optional
            TextFormField(
              controller: priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Precio estimado',
                prefixText: r'$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Submit button
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final item = ShoppingItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  quantity: double.tryParse(quantityCtrl.text),
                  unit: unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim(),
                  estimatedPrice: double.tryParse(priceCtrl.text),
                  isChecked: false,
                );

                ref.read(shoppingListNotifierProvider.notifier).addItem(item);
                Navigator.of(context).pop();
              },
              child: const Text('Agregar'),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
