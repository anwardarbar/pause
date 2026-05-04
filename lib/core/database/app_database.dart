import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// Enums stored as their .name string — mapping handled in LocalEventRepository
@DataClassName('FinancialEventRow')
@TableIndex(name: 'events_created_at', columns: {#createdAt})
@TableIndex(name: 'events_type_created_at', columns: {#type, #createdAt})
class FinancialEvents extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get category => text()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get source => text()();
  RealColumn get confidence => real().nullable()();
  TextColumn get rawInput => text().nullable()();
  TextColumn get reflection => text().nullable()();
  DateTimeColumn get reflectedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get editedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [FinancialEvents])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'pause_db');
  }
}
