import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_event.dart';
import 'filter_provider.dart';
import 'home_stats_provider.dart';
import 'repository_provider.dart';

class TimelineState {
  const TimelineState({
    required this.events,
    required this.hasMore,
    required this.page,
  });

  final List<FinancialEvent> events;
  final bool hasMore;
  final int page;

  static const empty = TimelineState(events: [], hasMore: false, page: 0);

  TimelineState copyWith({
    List<FinancialEvent>? events,
    bool? hasMore,
    int? page,
  }) {
    return TimelineState(
      events: events ?? this.events,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

const _pageSize = 50;

class TimelineNotifier extends AsyncNotifier<TimelineState> {
  @override
  Future<TimelineState> build() {
    // Rebuild whenever filters change
    ref.watch(filterProvider);
    return _fetchPage(0);
  }

  Future<TimelineState> _fetchPage(int page) async {
    final repo = ref.read(eventRepositoryProvider);
    final filter = ref.read(filterProvider);

    List<FinancialEvent> all = await repo.getByDateRange(
      filter.dateRange.from,
      filter.dateRange.to,
    );

    // Apply in-memory filters (category, payment, type)
    if (filter.category != null) {
      all = all.where((e) => e.category == filter.category).toList();
    }
    if (filter.paymentMethod != null) {
      all = all.where((e) => e.paymentMethod == filter.paymentMethod).toList();
    }
    if (filter.type != null) {
      all = all.where((e) => e.type == filter.type).toList();
    }

    final start = page * _pageSize;
    if (start >= all.length) {
      return TimelineState(events: [], hasMore: false, page: page);
    }

    final end = (start + _pageSize).clamp(0, all.length);
    final pageEvents = all.sublist(start, end);
    final hasMore = end < all.length;

    return TimelineState(events: pageEvents, hasMore: hasMore, page: page);
  }

  /// Appends the next page to the existing list (infinite scroll).
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;

    final nextPage = current.page + 1;
    final repo = ref.read(eventRepositoryProvider);
    final filter = ref.read(filterProvider);

    List<FinancialEvent> all = await repo.getByDateRange(
      filter.dateRange.from,
      filter.dateRange.to,
    );

    if (filter.category != null) {
      all = all.where((e) => e.category == filter.category).toList();
    }
    if (filter.paymentMethod != null) {
      all = all.where((e) => e.paymentMethod == filter.paymentMethod).toList();
    }
    if (filter.type != null) {
      all = all.where((e) => e.type == filter.type).toList();
    }

    final start = nextPage * _pageSize;
    if (start >= all.length) {
      state = AsyncData(current.copyWith(hasMore: false));
      return;
    }

    final end = (start + _pageSize).clamp(0, all.length);
    final newEvents = all.sublist(start, end);
    final hasMore = end < all.length;

    state = AsyncData(current.copyWith(
      events: [...current.events, ...newEvents],
      hasMore: hasMore,
      page: nextPage,
    ));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(0));
  }
}

final timelineProvider =
    AsyncNotifierProvider<TimelineNotifier, TimelineState>(
  TimelineNotifier.new,
  name: 'timelineProvider',
);

// ─── Recent-only provider for Home Screen ────────────────────────────────────
// Follows the home selected month — never FilterProvider.

final recentEventsProvider = FutureProvider<List<FinancialEvent>>(
  (ref) async {
    final repo = ref.watch(eventRepositoryProvider);
    final month = ref.watch(homeSelectedMonthProvider);
    final range = _monthRange(month);
    final all = await repo.getByDateRange(range.from, range.to);
    return all.take(5).toList();
  },
  name: 'recentEventsProvider',
);

DateRange _monthRange(DateTime month) {
  final from = DateTime(month.year, month.month, 1);
  final to = DateTime(month.year, month.month + 1, 1)
      .subtract(const Duration(milliseconds: 1));
  return DateRange(from: from, to: to);
}
