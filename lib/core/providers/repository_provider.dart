import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/event_repository.dart';
import '../repository/local_event_repository.dart';
import 'database_provider.dart';

/// UI and all other providers must use this — never LocalEventRepository directly.
final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => LocalEventRepository(ref.watch(appDatabaseProvider)),
  name: 'eventRepositoryProvider',
);
