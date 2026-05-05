import '../models/enums.dart';
import 'input_result.dart';

/// Validates and wraps typed text input.
/// Minimum 3 characters after trimming.
/// Never throws — returns a [TextInputError] instead.
class TextInputService {
  const TextInputService();

  static const int minLength = 3;

  /// Returns [InputResult] on success, [TextInputError] on validation failure.
  TextInputOutcome process(String raw) {
    final trimmed = raw.trim();

    if (trimmed.isEmpty) {
      return TextInputError(TextInputErrorType.empty);
    }

    if (trimmed.length < minLength) {
      return TextInputError(TextInputErrorType.tooShort);
    }

    return TextInputSuccess(
      InputResult(rawText: trimmed, source: InputSource.text),
    );
  }
}

// ─── Outcome types ────────────────────────────────────────────────────────────

sealed class TextInputOutcome {}

class TextInputSuccess extends TextInputOutcome {
  TextInputSuccess(this.result);
  final InputResult result;
}

class TextInputError extends TextInputOutcome {
  TextInputError(this.type);
  final TextInputErrorType type;

  String get message => switch (type) {
        TextInputErrorType.empty => 'Please enter something.',
        TextInputErrorType.tooShort =>
          'Too short — add a bit more detail.',
      };
}

enum TextInputErrorType { empty, tooShort }
