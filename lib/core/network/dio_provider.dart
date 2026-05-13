import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider that creates and configures the application-wide [Dio] instance.
///
/// Configuration:
/// - [connectTimeout] and [receiveTimeout] are set to 15 seconds.
/// - A [LogInterceptor] is added ONLY when [kDebugMode] is `true`
///   (logs request body + response body).
///
/// The [AuthInterceptor] is NOT attached here — it will be composed via a
/// separate provider or override in T-14/T-19 when auth state is available.
/// This keeps [dioProvider] decoupled from the auth feature.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  return dio;
});
