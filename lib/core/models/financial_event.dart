import 'enums.dart';

class FinancialEvent {
  const FinancialEvent({
    required this.id,
    required this.type,
    required this.amount,
    this.currency = 'INR',
    required this.category,
    this.paymentMethod,
    this.note,
    required this.source,
    this.confidence,
    this.rawInput,
    this.reflection,
    this.reflectedAt,
    required this.createdAt,
    this.editedAt,
  }) : assert(amount > 0, 'amount must be positive');

  final String id;
  final EventType type;
  final double amount;
  final String currency;
  final Category category;
  final PaymentMethod? paymentMethod;
  final String? note;
  final InputSource source;
  final double? confidence;

  // Cleared once user confirms (confidence >= 0.8) or edits any field
  final String? rawInput;

  // Only valid on EventType.expense — never set on saved events
  final ReflectionState? reflection;
  final DateTime? reflectedAt;

  final DateTime createdAt;
  final DateTime? editedAt;

  FinancialEvent copyWith({
    String? id,
    EventType? type,
    double? amount,
    String? currency,
    Category? category,
    Object? paymentMethod = _sentinel,
    Object? note = _sentinel,
    InputSource? source,
    Object? confidence = _sentinel,
    Object? rawInput = _sentinel,
    Object? reflection = _sentinel,
    Object? reflectedAt = _sentinel,
    DateTime? createdAt,
    Object? editedAt = _sentinel,
  }) {
    return FinancialEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      paymentMethod: paymentMethod == _sentinel
          ? this.paymentMethod
          : paymentMethod as PaymentMethod?,
      note: note == _sentinel ? this.note : note as String?,
      source: source ?? this.source,
      confidence:
          confidence == _sentinel ? this.confidence : confidence as double?,
      rawInput: rawInput == _sentinel ? this.rawInput : rawInput as String?,
      reflection: reflection == _sentinel
          ? this.reflection
          : reflection as ReflectionState?,
      reflectedAt: reflectedAt == _sentinel
          ? this.reflectedAt
          : reflectedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt == _sentinel ? this.editedAt : editedAt as DateTime?,
    );
  }

  // Equality by id only
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FinancialEvent && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'FinancialEvent(id: $id, type: $type, amount: $amount, category: $category)';
}

// Sentinel for nullable copyWith fields
const Object _sentinel = Object();
