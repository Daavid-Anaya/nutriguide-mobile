import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nutriguide_mobile/features/auth/data/secure_storage_service.dart';

/// Provider for the underlying [FlutterSecureStorage] instance.
///
/// Defined here so it can be overridden in tests.
final flutterSecureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

/// Provider for [SecureStorageService].
///
/// Injects the [FlutterSecureStorage] instance from [flutterSecureStorageProvider].
/// The auth notifier reads from this provider via [Ref.read].
final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(ref.read(flutterSecureStorageProvider)),
);
