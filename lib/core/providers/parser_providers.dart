import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../parsing/ai_parser_service.dart';
import '../parsing/parse_orchestrator.dart';
import '../parsing/rule_based_parser.dart';

final ruleBasedParserProvider = Provider<RuleBasedParser>(
  (ref) => RuleBasedParser(),
  name: 'ruleBasedParserProvider',
);

final aiParserServiceProvider = Provider<AIParserService>(
  (ref) => AIParserService(),
  name: 'aiParserServiceProvider',
);

final parseOrchestratorProvider = Provider<ParseOrchestrator>(
  (ref) => ParseOrchestrator(
    regexParser: ref.watch(ruleBasedParserProvider),
    aiParser: ref.watch(aiParserServiceProvider),
  ),
  name: 'parseOrchestratorProvider',
);
