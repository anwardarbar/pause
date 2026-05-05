import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

/// Initialized once in main() and injected via ProviderScope overrides.
/// Never call this directly — always override with a real instance.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider not overridden'),
  name: 'appDatabaseProvider',
);
