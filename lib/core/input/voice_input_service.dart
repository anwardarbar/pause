import 'dart:async';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/enums.dart';
import 'input_result.dart';

enum VoiceState { idle, listening, processing, result, error }

/// Voice input service using speech_to_text.
///
/// Gesture modes are handled by the UI layer (MicButton widget):
///   Hold mode  — UI calls [startListening] on press-down, [stopListening]
///                on release. MicButton shows release-to-stop affordance.
///   Tap mode   — UI calls [startListening] on first tap, [stopListening]
///                on second tap. MicButton shows pause icon while listening.
///
/// 3-second silence timeout is handled natively by [SpeechToText.pauseFor].
/// Locale is locked to en_IN for best Indian English / amount recognition.
///
/// Never throws to callers — emits [VoiceState.error] instead.
class VoiceInputService {
  VoiceInputService() : _stt = SpeechToText();

  final SpeechToText _stt;

  bool _initialized = false;

  // State stream
  final _stateController = StreamController<VoiceState>.broadcast();
  Stream<VoiceState> get stateStream => _stateController.stream;
  VoiceState _state = VoiceState.idle;
  VoiceState get currentState => _state;

  // Live transcript stream (interim words while user is speaking)
  final _transcriptController = StreamController<String>.broadcast();
  Stream<String> get transcriptStream => _transcriptController.stream;

  // Completed input — set when STT gives a final result
  final _resultController = StreamController<InputResult>.broadcast();
  Stream<InputResult> get resultStream => _resultController.stream;

  String _liveTranscript = '';
  String get liveTranscript => _liveTranscript;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      _initialized = await _stt.initialize(
        onError: (error) => _onSttError(error.errorMsg),
        onStatus: _onSttStatus,
      );
      return _initialized;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _stt.cancel();
    _stateController.close();
    _transcriptController.close();
    _resultController.close();
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  Future<void> startListening() async {
    if (_state != VoiceState.idle) return;

    final ready = await initialize();
    if (!ready) {
      _emitState(VoiceState.error);
      return;
    }

    _liveTranscript = '';
    _emitState(VoiceState.listening);
    HapticFeedback.mediumImpact();

    await _stt.listen(
      onResult: _onSttResult,
      localeId: 'en_IN',
      listenFor: const Duration(minutes: 5),  // hard cap — user stops manually
      pauseFor: const Duration(minutes: 5),   // effectively disabled — no silence auto-stop
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  /// Called by UI on release (hold mode) or second tap (tap mode).
  Future<void> stopListening() async {
    if (_state != VoiceState.listening) return;

    HapticFeedback.lightImpact();
    await _stt.stop();
    // _onSttStatus will fire 'done' → triggers processing
  }

  // ─── STT Callbacks ────────────────────────────────────────────────────────

  void _onSttResult(SpeechRecognitionResult result) {
    _liveTranscript = result.recognizedWords;
    _transcriptController.add(_liveTranscript);

    if (result.finalResult) {
      _onFinalTranscript(_liveTranscript);
    }
  }

  void _onSttStatus(String status) {
    // 'done' fires when STT stops — either via stop() or silence timeout
    if (status == 'done' || status == 'notListening') {
      if (_state == VoiceState.listening) {
        _onFinalTranscript(_liveTranscript);
      }
    }
  }

  void _onFinalTranscript(String text) {
    if (_state != VoiceState.listening) return;

    _emitState(VoiceState.processing);
    HapticFeedback.lightImpact();

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      _emitState(VoiceState.error);
      HapticFeedback.heavyImpact();
      return;
    }

    _resultController.add(InputResult(rawText: trimmed, source: InputSource.voice));
    _emitState(VoiceState.result);
    HapticFeedback.selectionClick();
  }

  void _onSttError(String message) {
    if (_state == VoiceState.idle) return; // already reset
    _emitState(VoiceState.error);
    HapticFeedback.heavyImpact();
  }

  // ─── State ────────────────────────────────────────────────────────────────

  void _emitState(VoiceState state) {
    _state = state;
    _stateController.add(state);
  }

  /// Called by UI after the user confirms or discards the result.
  void reset() {
    _liveTranscript = '';
    _emitState(VoiceState.idle);
  }
}
