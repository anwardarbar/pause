import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/enums.dart';
import '../models/parse_result.dart';

/// Calls Gemini 2.0 Flash to parse a natural-language financial input.
/// Never throws — returns null on any failure so the orchestrator can fallback.
class AIParserService {
  AIParserService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const _timeout = Duration(seconds: 5);

  static const _systemPrompt = '''
You are a financial event parser for an Indian expense tracking app.
Extract structured data from natural language descriptions.
Return ONLY raw JSON. No markdown fences. No explanation.

Schema:
{
  "type": "expense" | "saved",
  "amount": number,
  "currency": "INR",
  "category": "food"|"travel"|"shopping"|"bills"|"entertainment"|"misc",
  "paymentMethod": "upi"|"card"|"cash"|"netbanking"|"other"|null,
  "note": string,
  "confidence": number
}

Rules:
- "saved" = money intentionally NOT spent ("saved 500 by skipping lunch", "didnt go out saved 2000")
- "expense" = money actually spent
- note: 3-5 word clean summary. Never include the amount.
  Examples: "Dinner with friends", "Skipped lunch", "Uber to airport"
- paymentMethod: detect from context or null if not mentioned
  "gpay/phonepe/paytm" → upi, "swiped/card" → card, "cash" → cash
- confidence: 0.9 clear parse, 0.6 uncertain, 0.4 guessing
- If amount missing → confidence below 0.5
- Default currency INR
''';

  Future<ParseResult?> parse(String input) async {
    if (_apiKey.isEmpty) return null;

    ParseResult? result = await _callApi(input);

    // One retry on malformed JSON
    result ??= await _callApi(input);

    return result;
  }

  Future<ParseResult?> _callApi(String input) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': '$_systemPrompt\n\nInput: $input'},
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.1,
                'maxOutputTokens': 256,
              },
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final text = (body['candidates'] as List?)
          ?.firstOrNull?['content']?['parts']
              ?.firstOrNull?['text'] as String?;

      if (text == null || text.isEmpty) return null;

      return _parseJson(text.trim());
    } catch (_) {
      return null;
    }
  }

  ParseResult? _parseJson(String raw) {
    try {
      // Strip markdown fences if model ignores instructions
      final cleaned = raw
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();

      final map = jsonDecode(cleaned) as Map<String, dynamic>;

      final type = map['type'] == 'saved' ? EventType.saved : EventType.expense;
      final amount = (map['amount'] as num?)?.toDouble();
      final category = _parseCategory(map['category'] as String?);
      final paymentMethod = _parsePaymentMethod(map['paymentMethod'] as String?);
      final note = map['note'] as String?;
      final confidence = (map['confidence'] as num?)?.toDouble();

      return ParseResult(
        type: type,
        amount: amount,
        currency: map['currency'] as String? ?? 'INR',
        category: category,
        paymentMethod: paymentMethod,
        note: note,
        confidence: confidence,
        source: ParseSource.ai,
      );
    } catch (_) {
      return null;
    }
  }

  Category _parseCategory(String? raw) {
    if (raw == null) return Category.misc;
    return Category.values.firstWhere(
      (c) => c.name == raw,
      orElse: () => Category.misc,
    );
  }

  PaymentMethod? _parsePaymentMethod(String? raw) {
    if (raw == null) return null;
    return PaymentMethod.values.firstWhereOrNull((p) => p.name == raw);
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
