import '../models/enums.dart';

/// Output produced by both [VoiceInputService] and [TextInputService].
/// Carries the raw transcribed / typed text and how it was entered.
class InputResult {
  const InputResult({
    required this.rawText,
    required this.source,
  });

  final String rawText;
  final InputSource source;

  @override
  String toString() => 'InputResult(source: $source, text: "$rawText")';
}
