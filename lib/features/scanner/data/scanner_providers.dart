// Spec: SCANNER-STATE-001 sc2
// AD-14: Wiring providers for the scanner data layer.
// Verified indirectly in T-05 (ProductDetailNotifier integration tests).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutriguide_mobile/core/network/dio_provider.dart';
import 'package:nutriguide_mobile/core/storage/storage_providers.dart';
import 'package:nutriguide_mobile/features/scanner/data/open_food_facts_client.dart';
import 'package:nutriguide_mobile/features/scanner/data/scanner_repository_impl.dart';
import 'package:nutriguide_mobile/features/scanner/domain/scanner_repository.dart';

/// Provides the [OpenFoodFactsClient] configured with the application [Dio] instance.
///
/// Reads [dioProvider] — the app-wide Dio already has timeouts and logging
/// configured (AD-05). This client adds no extra configuration.
final openFoodFactsClientProvider = Provider<OpenFoodFactsClient>(
  (ref) => OpenFoodFactsClient(ref.read(dioProvider)),
);

/// Provides the concrete [ScannerRepository] implementation.
///
/// Wires [OpenFoodFactsClient] (network) and the Hive products box (cache)
/// into [ScannerRepositoryImpl]. Both dependencies are read (not watched)
/// because they are stable singletons that do not change at runtime.
///
/// The products box must be overridden in [ProviderScope] before use
/// (see [productsBoxProvider] in storage_providers.dart).
final scannerRepositoryProvider = Provider<ScannerRepository>(
  (ref) => ScannerRepositoryImpl(
    client: ref.read(openFoodFactsClientProvider),
    productsBox: ref.read(productsBoxProvider),
  ),
);
