import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enums.dart';

// ─── DateRange ────────────────────────────────────────────────────────────────

class DateRange {
  const DateRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  /// 12:00:00 AM of the first day → 11:59:59.999 PM of the last day.
  static DateRange currentMonth() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
    return DateRange(from: from, to: to);
  }

  static DateRange forDay(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
    return DateRange(from: from, to: to);
  }

  static DateRange lastDays(int days) {
    final now = DateTime.now();
    final to = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final from = DateTime(now.year, now.month, now.day - (days - 1));
    return DateRange(from: from, to: to);
  }

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

// ─── FilterState ──────────────────────────────────────────────────────────────

class FilterState {
  const FilterState({
    required this.dateRange,
    this.category,
    this.paymentMethod,
    this.type,
  });

  final DateRange dateRange;
  final Category? category;
  final PaymentMethod? paymentMethod;
  final EventType? type;

  FilterState copyWith({
    DateRange? dateRange,
    Object? category = _sentinel,
    Object? paymentMethod = _sentinel,
    Object? type = _sentinel,
  }) {
    return FilterState(
      dateRange: dateRange ?? this.dateRange,
      category:
          category == _sentinel ? this.category : category as Category?,
      paymentMethod: paymentMethod == _sentinel
          ? this.paymentMethod
          : paymentMethod as PaymentMethod?,
      type: type == _sentinel ? this.type : type as EventType?,
    );
  }

  FilterState clearCategory() => copyWith(category: null);
  FilterState clearPaymentMethod() => copyWith(paymentMethod: null);
  FilterState clearType() => copyWith(type: null);
  FilterState clearAll() => FilterState(dateRange: dateRange);

  @override
  bool operator ==(Object other) =>
      other is FilterState &&
      other.dateRange == dateRange &&
      other.category == category &&
      other.paymentMethod == paymentMethod &&
      other.type == type;

  @override
  int get hashCode =>
      Object.hash(dateRange, category, paymentMethod, type);
}

const Object _sentinel = Object();

// ─── Provider ─────────────────────────────────────────────────────────────────

class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => FilterState(dateRange: DateRange.currentMonth());

  void setDateRange(DateRange range) =>
      state = state.copyWith(dateRange: range);

  void setCategory(Category? category) =>
      state = state.copyWith(category: category);

  void setPaymentMethod(PaymentMethod? method) =>
      state = state.copyWith(paymentMethod: method);

  void setType(EventType? type) => state = state.copyWith(type: type);

  void clearCategory() => state = state.clearCategory();
  void clearPaymentMethod() => state = state.clearPaymentMethod();
  void clearType() => state = state.clearType();
  void clearAll() => state = state.clearAll();
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(
  FilterNotifier.new,
  name: 'filterProvider',
);
