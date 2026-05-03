import 'enums.dart';

// ParseResult is a CANDIDATE — not a saved event.
// It becomes a FinancialEvent only after the user confirms.
//
// When source == ParseSource.manual: type and category are UI-level defaults
// (expense / misc). The confirmation UI MUST prompt the user to set these
// explicitly. Defaults are last-resort fallbacks only.
class ParseResult {
  const ParseResult({
    this.type = EventType.expense,
    this.amount,
    this.currency = AppConstants.defaultCurrency,
    this.category = Category.misc,
    this.paymentMethod,
    this.note,
    this.confidence,
    required this.source,
  });

  final EventType type;
  final double? amount;
  final String currency;
  final Category category;
  final PaymentMethod? paymentMethod;
  final String? note;

  // null for regex / manual source
  final double? confidence;
  final ParseSource source;

  bool get isManual => source == ParseSource.manual;
  bool get isHighConfidence => confidence != null && confidence! >= 0.8;

  ParseResult copyWith({
    EventType? type,
    Object? amount = _sentinel,
    String? currency,
    Category? category,
    Object? paymentMethod = _sentinel,
    Object? note = _sentinel,
    Object? confidence = _sentinel,
    ParseSource? source,
  }) {
    return ParseResult(
      type: type ?? this.type,
      amount: amount == _sentinel ? this.amount : amount as double?,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      paymentMethod: paymentMethod == _sentinel
          ? this.paymentMethod
          : paymentMethod as PaymentMethod?,
      note: note == _sentinel ? this.note : note as String?,
      confidence:
          confidence == _sentinel ? this.confidence : confidence as double?,
      source: source ?? this.source,
    );
  }

  @override
  String toString() =>
      'ParseResult(source: $source, type: $type, amount: $amount, confidence: $confidence)';
}

const Object _sentinel = Object();

class AppConstants {
  AppConstants._();

  static const String defaultCurrency = 'INR';
}
