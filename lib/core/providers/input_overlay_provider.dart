import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../input/voice_input_service.dart';
import '../models/parse_result.dart';
import 'parser_providers.dart';
import 'repository_provider.dart';
import 'home_stats_provider.dart';
import 'timeline_provider.dart';
import 'detail_stats_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class InputOverlayState {
  const InputOverlayState({
    this.isVisible = false,
    this.voiceState = VoiceState.idle,
    this.liveTranscript = '',
    this.parseResult,
    this.editedResult,
  });

  final bool isVisible;
  final VoiceState voiceState;
  final String liveTranscript;

  /// The raw result from the orchestrator.
  final ParseResult? parseResult;

  /// User edits applied on top of parseResult.
  /// Starts as a copy of parseResult — all edits mutate this only.
  final ParseResult? editedResult;

  bool get hasResult => parseResult != null;

  InputOverlayState copyWith({
    bool? isVisible,
    VoiceState? voiceState,
    String? liveTranscript,
    Object? parseResult = _sentinel,
    Object? editedResult = _sentinel,
  }) {
    return InputOverlayState(
      isVisible: isVisible ?? this.isVisible,
      voiceState: voiceState ?? this.voiceState,
      liveTranscript: liveTranscript ?? this.liveTranscript,
      parseResult: parseResult == _sentinel
          ? this.parseResult
          : parseResult as ParseResult?,
      editedResult: editedResult == _sentinel
          ? this.editedResult
          : editedResult as ParseResult?,
    );
  }
}

const Object _sentinel = Object();

// ─── Notifier ─────────────────────────────────────────────────────────────────

class InputOverlayNotifier extends Notifier<InputOverlayState> {
  @override
  InputOverlayState build() => const InputOverlayState();

  // ── Visibility ──────────────────────────────────────────────────────────────

  void show() => state = state.copyWith(isVisible: true);

  void hide() => state = const InputOverlayState(); // full reset

  // ── Voice state passthrough ─────────────────────────────────────────────────

  void updateVoiceState(VoiceState voiceState) =>
      state = state.copyWith(voiceState: voiceState);

  void updateTranscript(String text) =>
      state = state.copyWith(liveTranscript: text);

  // ── Parsing ─────────────────────────────────────────────────────────────────

  Future<void> parseInput(String rawText) async {
    state = state.copyWith(voiceState: VoiceState.processing);

    final orchestrator = ref.read(parseOrchestratorProvider);
    final result = await orchestrator.parse(rawText);

    state = state.copyWith(
      voiceState: VoiceState.result,
      parseResult: result,
      editedResult: result, // edits start as a copy
    );
  }

  // ── Field editing ────────────────────────────────────────────────────────────

  void applyEdit(ParseResult updated) =>
      state = state.copyWith(editedResult: updated);

  // ── Confirm ──────────────────────────────────────────────────────────────────

  Future<void> confirmAndSave(String eventId, DateTime createdAt) async {
    final edited = state.editedResult;
    if (edited == null) return;

    final original = state.parseResult;
    final anyFieldEdited = edited != original;

    // rawInput rule: null if confidence >= 0.8 AND confirmed, OR any field edited
    final clearRawInput =
        anyFieldEdited || (edited.confidence != null && edited.confidence! >= 0.8);

    final event = edited.toFinancialEvent(
      id: eventId,
      createdAt: createdAt,
      clearRawInput: clearRawInput,
    );

    final repo = ref.read(eventRepositoryProvider);
    await repo.save(event);

    // Invalidate all three providers
    ref.invalidate(homeStatsProvider);
    ref.invalidate(timelineProvider);
    ref.invalidate(detailStatsProvider);

    hide();
  }

  void discard() => hide();
}

final inputOverlayProvider =
    NotifierProvider<InputOverlayNotifier, InputOverlayState>(
  InputOverlayNotifier.new,
  name: 'inputOverlayProvider',
);
