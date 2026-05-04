import '../models/enums.dart';
import '../models/financial_event.dart';

abstract class EventRepository {
  // Write
  Future<void> save(FinancialEvent event);
  Future<void> update(FinancialEvent event);
  Future<void> delete(String id);

  // Read
  Future<List<FinancialEvent>> getAll();
  Future<List<FinancialEvent>> getByDateRange(DateTime from, DateTime to);
  Future<List<FinancialEvent>> getByType(EventType type);
  Future<List<FinancialEvent>> getByCategory(Category category);
  Future<FinancialEvent?> getById(String id);

  // rawInput != null — defaults to last 30 days; pass explicit range to override
  Future<List<FinancialEvent>> getPendingReview({DateTime? from, DateTime? to});

  // Aggregates
  Future<double> getTotalByType(EventType type, DateTime from, DateTime to);
  Future<Map<Category, double>> getCategoryBreakdown(
    EventType type,
    DateTime from,
    DateTime to,
  );
}
