import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/enums.dart';
import '../models/financial_event.dart';
import 'event_repository.dart';

// UI and providers must import EventRepository only — never this class directly.
class LocalEventRepository implements EventRepository {
  const LocalEventRepository(this._db);

  final AppDatabase _db;

  // ─── Write ────────────────────────────────────────────────────────────────

  @override
  Future<void> save(FinancialEvent event) async {
    await _db.into(_db.financialEvents).insert(_toCompanion(event));
  }

  @override
  Future<void> update(FinancialEvent event) async {
    await (_db.update(_db.financialEvents)
          ..where((t) => t.id.equals(event.id)))
        .write(_toCompanion(event));
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.financialEvents)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  @override
  Future<List<FinancialEvent>> getAll() async {
    final rows = await (_db.select(_db.financialEvents)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<FinancialEvent>> getByDateRange(
      DateTime from, DateTime to) async {
    final rows = await (_db.select(_db.financialEvents)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(from) &
              t.createdAt.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<FinancialEvent>> getByType(EventType type) async {
    final rows = await (_db.select(_db.financialEvents)
          ..where((t) => t.type.equals(type.name))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<List<FinancialEvent>> getByCategory(Category category) async {
    final rows = await (_db.select(_db.financialEvents)
          ..where((t) => t.category.equals(category.name))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<FinancialEvent?> getById(String id) async {
    final row = await (_db.select(_db.financialEvents)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toModel(row) : null;
  }

  @override
  Future<List<FinancialEvent>> getPendingReview({
    DateTime? from,
    DateTime? to,
  }) async {
    final now = DateTime.now().toUtc();
    final effectiveFrom = from ?? now.subtract(const Duration(days: 30));
    final effectiveTo = to ?? now;

    final rows = await (_db.select(_db.financialEvents)
          ..where((t) =>
              t.rawInput.isNotNull() &
              t.createdAt.isBiggerOrEqualValue(effectiveFrom) &
              t.createdAt.isSmallerOrEqualValue(effectiveTo))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toModel).toList();
  }

  // ─── Aggregates ───────────────────────────────────────────────────────────

  @override
  Future<double> getTotalByType(
      EventType type, DateTime from, DateTime to) async {
    final amountSum = _db.financialEvents.amount.sum();
    final query = _db.selectOnly(_db.financialEvents)
      ..addColumns([amountSum])
      ..where(_db.financialEvents.type.equals(type.name) &
          _db.financialEvents.createdAt.isBiggerOrEqualValue(from) &
          _db.financialEvents.createdAt.isSmallerOrEqualValue(to));

    final row = await query.getSingleOrNull();
    return row?.read(amountSum) ?? 0.0;
  }

  @override
  Future<Map<Category, double>> getCategoryBreakdown(
    EventType type,
    DateTime from,
    DateTime to,
  ) async {
    final categoryCol = _db.financialEvents.category;
    final amountSum = _db.financialEvents.amount.sum();

    final query = _db.selectOnly(_db.financialEvents)
      ..addColumns([categoryCol, amountSum])
      ..where(_db.financialEvents.type.equals(type.name) &
          _db.financialEvents.createdAt.isBiggerOrEqualValue(from) &
          _db.financialEvents.createdAt.isSmallerOrEqualValue(to))
      ..groupBy([categoryCol]);

    final rows = await query.get();
    final result = <Category, double>{};
    for (final row in rows) {
      final rawCategory = row.read(categoryCol);
      final sum = row.read(amountSum);
      if (rawCategory != null && sum != null) {
        result[Category.values.byName(rawCategory)] = sum;
      }
    }
    return result;
  }

  // ─── Mapping ──────────────────────────────────────────────────────────────

  FinancialEvent _toModel(FinancialEventRow row) {
    return FinancialEvent(
      id: row.id,
      type: EventType.values.byName(row.type),
      amount: row.amount,
      currency: row.currency,
      category: Category.values.byName(row.category),
      paymentMethod: row.paymentMethod != null
          ? PaymentMethod.values.byName(row.paymentMethod!)
          : null,
      note: row.note,
      source: InputSource.values.byName(row.source),
      confidence: row.confidence,
      rawInput: row.rawInput,
      reflection: row.reflection != null
          ? ReflectionState.values.byName(row.reflection!)
          : null,
      reflectedAt: row.reflectedAt,
      createdAt: row.createdAt,
      editedAt: row.editedAt,
    );
  }

  FinancialEventsCompanion _toCompanion(FinancialEvent event) {
    return FinancialEventsCompanion(
      id: Value(event.id),
      type: Value(event.type.name),
      amount: Value(event.amount),
      currency: Value(event.currency),
      category: Value(event.category.name),
      paymentMethod: Value(event.paymentMethod?.name),
      note: Value(event.note),
      source: Value(event.source.name),
      confidence: Value(event.confidence),
      rawInput: Value(event.rawInput),
      reflection: Value(event.reflection?.name),
      reflectedAt: Value(event.reflectedAt),
      createdAt: Value(event.createdAt),
      editedAt: Value(event.editedAt),
    );
  }
}
