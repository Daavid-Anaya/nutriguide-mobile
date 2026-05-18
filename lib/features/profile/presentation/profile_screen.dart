// Spec: PROFILE-UI-001, PROFILE-UI-002, PROFILE-UI-003, AUTH-SIGNOUT-001
//       AVATAR-UI-001 (S1, S2, S3, S4)
// Design: AD-38 (6 states), AD-39 (HookConsumerWidget for form), AD-61 (avatar via picker)
// TDD: T-12 [GREEN] — Full ProfileScreen implementation replacing 18-line placeholder.
// TDD: Phase 6 [GREEN] — Added sign-out button.
// TDD: T-10 [GREEN] — Avatar upload UI: tappable avatar, "Cambiar foto", removed avatarUrl field.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutriguide_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:nutriguide_mobile/features/profile/domain/user_profile.dart';
import 'package:nutriguide_mobile/features/profile/presentation/providers/profile_notifier.dart';
import 'package:nutriguide_mobile/features/profile/presentation/widgets/profile_avatar.dart';

/// Full profile screen — manages read / edit / saving / uploading / error states.
///
/// Watches [profileNotifierProvider] and delegates to sub-widgets based on the
/// current [ProfileState] variant. Wraps the form in [_ProfileForm]
/// (HookConsumerWidget) to manage TextEditingControllers with flutter_hooks.
///
/// Spec: PROFILE-UI-001, PROFILE-UI-002, PROFILE-UI-003 | Design: AD-38/39.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(profileNotifierProvider);

    // T-14: Wire SnackBar success listener — fires when Saving → Data
    ref.listen<AsyncValue<ProfileState>>(profileNotifierProvider,
        (previous, next) {
      if (previous?.value is ProfileSaving && next.value is ProfileData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil guardado exitosamente')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        centerTitle: true,
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () =>
              ref.read(profileNotifierProvider.notifier).retry(),
        ),
        data: (profileState) => switch (profileState) {
          ProfileLoading() => const Center(child: CircularProgressIndicator()),
          ProfileData(:final profile) => _ProfileDataView(
              profile: profile,
              isUploading: false,
              onEdit: () =>
                  ref.read(profileNotifierProvider.notifier).startEdit(),
              onUpdateAvatar: () =>
                  ref.read(profileNotifierProvider.notifier).updateAvatar(),
              onSignOut: () =>
                  ref.read(authNotifierProvider.notifier).signOut(),
            ),
          // AVATAR-UI-001-S2: Show data view with uploading overlay
          ProfileUploading(:final profile) => _ProfileDataView(
              profile: profile,
              isUploading: true,
              onEdit: () {},
              onUpdateAvatar: () {},
              onSignOut: () {},
            ),
          ProfileEditing(:final profile) => _ProfileForm(
              profile: profile,
              enabled: true,
              onSave: (name, url, budget) => ref
                  .read(profileNotifierProvider.notifier)
                  .saveProfile(name, url, budget),
              onCancel: () =>
                  ref.read(profileNotifierProvider.notifier).cancelEdit(),
            ),
          ProfileSaving(:final profile) => _ProfileForm(
              profile: profile,
              enabled: false,
              onSave: (name, url, budget) {},
              onCancel: () {},
            ),
          ProfileError(:final message) => _ErrorView(
              message: message,
              onRetry: () =>
                  ref.read(profileNotifierProvider.notifier).retry(),
            ),
        },
      ),
    );
  }
}

// ── Read-only data view ────────────────────────────────────────────────────────
class _ProfileDataView extends StatelessWidget {
  const _ProfileDataView({
    required this.profile,
    required this.isUploading,
    required this.onEdit,
    required this.onUpdateAvatar,
    required this.onSignOut,
  });

  final UserProfile profile;
  final bool isUploading;
  final VoidCallback onEdit;
  final VoidCallback onUpdateAvatar;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final budgetText = profile.groceryBudget != null
        ? NumberFormat.currency(locale: 'es_AR', symbol: r'$')
            .format(profile.groceryBudget)
        : 'Sin presupuesto';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // AVATAR-UI-001-S1: Tappable avatar with GestureDetector
          GestureDetector(
            onTap: onUpdateAvatar,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ProfileAvatar(avatarUrl: profile.avatarUrl, radius: 48),
                // AVATAR-UI-001-S2: Show spinner overlay when uploading
                if (isUploading) const CircularProgressIndicator(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // AVATAR-UI-001-S1: "Cambiar foto" tappable text button
          TextButton.icon(
            onPressed: onUpdateAvatar,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Cambiar foto'),
          ),
          const SizedBox(height: 8),
          Text(
            profile.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Presupuesto: $budgetText',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isUploading ? null : onEdit,
              child: const Text('Editar perfil'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isUploading ? null : onSignOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit / Saving form ─────────────────────────────────────────────────────────
class _ProfileForm extends HookConsumerWidget {
  const _ProfileForm({
    required this.profile,
    required this.enabled,
    required this.onSave,
    required this.onCancel,
  });

  final UserProfile profile;
  final bool enabled;
  final void Function(String name, String? avatarUrl, double? groceryBudget)
      onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameCtrl = useTextEditingController(text: profile.name);
    // AVATAR-UI-001-S3: avatarUrl TextFormField REMOVED — managed by updateAvatar()
    final budgetCtrl = useTextEditingController(
      text: profile.groceryBudget != null
          ? profile.groceryBudget.toString()
          : '',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            const SizedBox(height: 16),
            // AVATAR-UI-001-S4: ProfileAvatar static (non-tappable) in form
            ProfileAvatar(avatarUrl: profile.avatarUrl, radius: 48),
            const SizedBox(height: 24),
            TextFormField(
              controller: nameCtrl,
              enabled: enabled,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: budgetCtrl,
              enabled: enabled,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Presupuesto semanal'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final parsed = double.tryParse(v.trim());
                if (parsed == null) return 'Ingresá un número válido';
                if (parsed <= 0) return 'El presupuesto debe ser positivo';
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: enabled
                    ? () {
                        if (formKey.currentState!.validate()) {
                          final budgetText = budgetCtrl.text.trim();
                          final budget = budgetText.isEmpty
                              ? null
                              : double.tryParse(budgetText);
                          // AVATAR-UI-001-S3: Pass existing avatarUrl — not from a text field
                          onSave(nameCtrl.text, profile.avatarUrl, budget);
                        }
                      }
                    : null,
                child: const Text('Guardar'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: enabled ? onCancel : null,
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
