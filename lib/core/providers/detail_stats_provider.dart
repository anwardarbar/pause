import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';
import 'filter_provider.dart';
import 'repository_provider.dart';

class DetailStats {
  const DetailStats({
    required this.totalExpense,
    required this.totalSaved,
    required this.expenseByCategory,
    required this.savedByCategory,
  });

  final double totalExpense;
  final double totalSaved;
  final Map<Category, double> expenseByCategory;
  final Map<Category, double> savedByCategory;

  static const empty = DetailStats(
    totalExpense: 0,
    totalSaved: 0,
    expenseByCategory: {},
    savedByCategory: {},
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class DetailStatsNotifier extends AsyncNotifier<DetailStats> {
  @override
  Future<DetailStats> build() {
    ref.watch(filterProvider);
    return _fetch();
  }

  Future<DetailStats> _fetch() async {
    final repo = ref.read(eventRepositoryProvider);
    final filter = ref.read(filterProvider);
    final from = filter.dateRange.from;
    final to = filter.dateRange.to;

    final results = await Future.wait([
      repo.getTotalByType(EventType.expense, from, to),
      repo.getTotalByType(EventType.saved, from, to),
      repo.getCategoryBreakdown(EventType.expense, from, to),
      repo.getCategoryBreakdown(EventType.saved, from, to),
    ]);

    return DetailStats(
      totalExpense: results[0] as double,
      totalSaved: results[1] as double,
      expenseByCategory: results[2] as Map<Category, double>,
      savedByCategory: results[3] as Map<Category, double>,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final detailStatsProvider =
    AsyncNotifierProvider<DetailStatsNotifier, DetailStats>(
  DetailStatsNotifier.new,
  name: 'detailStatsProvider',
);
