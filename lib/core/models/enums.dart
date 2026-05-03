enum EventType {
  expense,
  saved;

  String get displayName => switch (this) {
        EventType.expense => 'Expense',
        EventType.saved => 'Saved',
      };
}

enum Category {
  food,
  travel,
  shopping,
  bills,
  entertainment,
  misc;

  String get displayName => switch (this) {
        Category.food => 'Food',
        Category.travel => 'Travel',
        Category.shopping => 'Shopping',
        Category.bills => 'Bills',
        Category.entertainment => 'Entertainment',
        Category.misc => 'Misc',
      };
}

enum PaymentMethod {
  upi,
  card,
  cash,
  netbanking,
  other;

  String get displayName => switch (this) {
        PaymentMethod.upi => 'UPI',
        PaymentMethod.card => 'Card',
        PaymentMethod.cash => 'Cash',
        PaymentMethod.netbanking => 'Net Banking',
        PaymentMethod.other => 'Other',
      };
}

enum InputSource {
  voice,
  text;

  String get displayName => switch (this) {
        InputSource.voice => 'Voice',
        InputSource.text => 'Text',
      };
}

enum ReflectionState {
  worthIt,
  mehh,
  notWorthIt;

  String get displayName => switch (this) {
        ReflectionState.worthIt => 'Worth it',
        ReflectionState.mehh => 'Mehh',
        ReflectionState.notWorthIt => 'Not worth it',
      };
}

enum ParseSource {
  ai,
  regex,
  manual;

  String get displayName => switch (this) {
        ParseSource.ai => 'AI',
        ParseSource.regex => 'Auto-detected',
        ParseSource.manual => 'Manual',
      };
}
