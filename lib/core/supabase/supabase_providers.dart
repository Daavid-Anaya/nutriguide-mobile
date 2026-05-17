import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides the singleton [SupabaseClient] initialized in main.dart.
///
/// AD-45: Always available after [Supabase.initialize()] completes.
/// SUPABASE-CONFIG-001-S4: Multiple reads return the same instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
