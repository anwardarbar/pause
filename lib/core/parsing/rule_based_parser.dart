import '../models/enums.dart';
import '../models/parse_result.dart';

/// Offline regex parser — always runs first to avoid unnecessary AI calls.
/// Returns a [ParseResult] with [ParseSource.regex].
/// If [ParseResult.amount] is null or [_typeDetected] is false,
/// the orchestrator escalates to AI.
class RuleBasedParser {
  RuleBasedParser();

  // ─── Patterns ─────────────────────────────────────────────────────────────

  static final _amountPattern =
      RegExp(r'₹?([\d,]+(?:\.\d+)?)', caseSensitive: false);

  static final _expensePattern = RegExp(
    r'\b(spent|paid|bought|purchased|spend|paying|ordered|booked|subscribed)\b',
    caseSensitive: false,
  );

  static final _savedPattern = RegExp(
    r"\b(saved|skipped|skip|avoided|didnt spend|didn't spend|resisted|held back|cut back)\b",
    caseSensitive: false,
  );

  // Category keyword maps
  static final _categoryPatterns = <Category, RegExp>{
    Category.food: RegExp(
      r'\b(food|dinner|lunch|breakfast|snack|restaurant|cafe|swiggy|zomato|hotel|meal|coffee|chai|eat|biryani|pizza|burger)\b',
      caseSensitive: false,
    ),
    Category.travel: RegExp(
      r'\b(uber|ola|taxi|cab|auto|flight|train|metro|bus|travel|airport|rapido|petrol|fuel|toll|commute)\b',
      caseSensitive: false,
    ),
    Category.shopping: RegExp(
      r'\b(amazon|flipkart|shop|shopping|clothes|shirt|shoes|myntra|meesho|dress|jeans|grocery|kirana|market)\b',
      caseSensitive: false,
    ),
    Category.bills: RegExp(
      r'\b(electricity|rent|bill|emi|subscription|recharge|internet|wifi|broadband|insurance|tax|maintenance)\b',
      caseSensitive: false,
    ),
    Category.entertainment: RegExp(
      r'\b(movie|netflix|prime|hotstar|spotify|game|concert|cricket|theatre|show|outing|party)\b',
      caseSensitive: false,
    ),
  };

  static final _paymentPatterns = <PaymentMethod, RegExp>{
    PaymentMethod.upi: RegExp(
      r'\b(gpay|google pay|phonepe|paytm|upi|bhim|neft|imps)\b',
      caseSensitive: false,
    ),
    PaymentMethod.card: RegExp(
      r'\b(card|swiped|credit|debit|visa|mastercard|rupay)\b',
      caseSensitive: false,
    ),
    PaymentMethod.cash: RegExp(r'\b(cash|note|coin)\b', caseSensitive: false),
    PaymentMethod.netbanking: RegExp(
      r'\b(netbanking|net banking|bank transfer|transferred)\b',
      caseSensitive: false,
    ),
  };

  // ─── Public API ───────────────────────────────────────────────────────────

  ParseResult parse(String input) {
    final text = input.trim();

    final amount = _extractAmount(text);
    final typeResult = _extractType(text);
    final category = _extractCategory(text);
    final paymentMethod = _extractPaymentMethod(text);
    final note = _extractNote(text, typeResult.$1);

    return ParseResult(
      type: typeResult.$1,
      amount: amount,
      category: category,
      paymentMethod: paymentMethod,
      note: note,
      source: ParseSource.regex,
      // No confidence for regex — orchestrator checks typeDetected + amount
    );
  }

  /// Whether the parser was able to determine type from context.
  /// Used by orchestrator to decide if AI escalation is needed.
  bool hasTypeContext(String input) => _hasExpenseKeyword(input) || _hasSavedKeyword(input);

  // ─── Extractors ───────────────────────────────────────────────────────────

  double? _extractAmount(String text) {
    final match = _amountPattern.firstMatch(text);
    if (match == null) return null;
    final raw = match.group(1)!.replaceAll(',', '');
    return double.tryParse(raw);
  }

  /// Returns (EventType, typeWasDetected).
  (EventType, bool) _extractType(String text) {
    if (_hasSavedKeyword(text)) return (EventType.saved, true);
    if (_hasExpenseKeyword(text)) return (EventType.expense, true);
    return (EventType.expense, false); // undetected default
  }

  bool _hasExpenseKeyword(String text) => _expensePattern.hasMatch(text);
  bool _hasSavedKeyword(String text) => _savedPattern.hasMatch(text);

  Category _extractCategory(String text) {
    for (final entry in _categoryPatterns.entries) {
      if (entry.value.hasMatch(text)) return entry.key;
    }
    return Category.misc;
  }

  PaymentMethod? _extractPaymentMethod(String text) {
    for (final entry in _paymentPatterns.entries) {
      if (entry.value.hasMatch(text)) return entry.key;
    }
    return null;
  }

  String? _extractNote(String text, EventType type) {
    // Saved: extract phrase after "by" / "on" / "skipping"
    if (type == EventType.saved) {
      final byMatch =
          RegExp(r'\bby\s+(.+?)(?:\s+\d|$)', caseSensitive: false).firstMatch(text);
      if (byMatch != null) {
        return _titleCase(byMatch.group(1)!.trim());
      }
    }
    // Expense: extract phrase after "on" / "for"
    final onMatch =
        RegExp(r'\b(?:on|for)\s+([a-zA-Z\s]+?)(?:\s+(?:via|with|using|by|\d)|$)',
                caseSensitive: false)
            .firstMatch(text);
    if (onMatch != null) {
      return _titleCase(onMatch.group(1)!.trim());
    }
    return null;
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}
