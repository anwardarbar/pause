import '../models/enums.dart';
import '../models/parse_result.dart';
import 'ai_parser_service.dart';
import 'rule_based_parser.dart';

/// Orchestrates parsing in three tiers — optimised to save AI tokens:
///
/// Tier 1 — Regex (always runs first, free, instant)
///   → Returns result if it extracted BOTH amount AND type context.
///
/// Tier 2 — Gemini 2.0 Flash (only called when regex is incomplete)
///   → Triggered when regex found no amount, or could not determine type.
///   → 5s timeout, 1 retry on malformed JSON.
///
/// Tier 3 — Manual (last resort)
///   → Returns an empty ParseResult; UI must prompt user to fill all fields.
///
/// Never throws to callers.
class ParseOrchestrator {
  const ParseOrchestrator({
    required RuleBasedParser regexParser,
    required AIParserService aiParser,
  })  : _regexParser = regexParser,
        _aiParser = aiParser;

  final RuleBasedParser _regexParser;
  final AIParserService _aiParser;

  Future<ParseResult> parse(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return _manualResult();

    // ── Tier 1: Regex ────────────────────────────────────────────────────────
    final regexResult = _regexParser.parse(trimmed);
    final hasAmount = regexResult.amount != null;
    final hasType = _regexParser.hasTypeContext(trimmed);

    if (hasAmount && hasType) {
      // Regex fully handled it — no AI needed
      return regexResult;
    }

    // ── Tier 2: AI ───────────────────────────────────────────────────────────
    // Called only when regex is incomplete (missing amount OR ambiguous type)
    try {
      final aiResult = await _aiParser.parse(trimmed);
      if (aiResult != null && aiResult.amount != null) {
        return aiResult;
      }
    } catch (_) {
      // AI failure is silent — fall through to manual
    }

    // ── Tier 3: Manual ───────────────────────────────────────────────────────
    // If regex got the amount but type was ambiguous, carry amount over.
    // UI will show all fields for user to confirm / fill.
    if (hasAmount) {
      return regexResult.copyWith(
        source: ParseSource.manual,
        // type is already set to expense as default — UI must prompt user
      );
    }

    return _manualResult();
  }

  ParseResult _manualResult() => const ParseResult(
        type: EventType.expense, // UI-level default — user must confirm
        category: Category.misc, // UI-level default — user must confirm
        source: ParseSource.manual,
      );
}
