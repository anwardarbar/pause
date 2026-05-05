import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';
import 'filter_provider.dart';
import 'repository_provider.dart';

class HomeStats {
  const HomeStats({
    required this.totalExpense,
    required this.totalSaved,
    required this.dateRange,
  });

  final double totalExpense;
  final double totalSaved;
  final DateRange dateRange;

  static final empty = HomeStats(
    totalExpense: 0,
    totalSaved: 0,
    dateRange: DateRange(
      from: DateTime.utc(1970),
      to: DateTime.utc(1970),
    ),
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class HomeStatsNotifier extends AsyncNotifier<HomeStats> {
  @override
  Future<HomeStats> build() => _fetch();

  Future<HomeStats> _fetch() async {
    final repo = ref.watch(eventRepositoryProvider);
    // Home screen always uses current month — never watches FilterProvider
    final range = DateRange.currentMonth();

    final results = await Future.wait([
      repo.getTotalByType(EventType.expense, range.from, range.to),
      repo.getTotalByType(EventType.saved, range.from, range.to),
    ]);

    return HomeStats(
      totalExpense: results[0],
      totalSaved: results[1],
      dateRange: range,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final homeStatsProvider =
    AsyncNotifierProvider<HomeStatsNotifier, HomeStats>(
  HomeStatsNotifier.new,
  name: 'homeStatsProvider',
);
