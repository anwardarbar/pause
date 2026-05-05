import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/input/voice_input_service.dart';
import '../../core/input/text_input_service.dart';
import '../../core/providers/input_overlay_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/home/widgets/mic_button.dart';
import 'confirmation_card.dart';

/// Full-screen overlay that handles both voice and text input flows.
/// Always present in the widget tree — animates in/out based on provider state.
/// Place this at the top of the app Stack (Layer 9 wires this).
class InputOverlay extends ConsumerStatefulWidget {
  const InputOverlay({super.key});

  @override
  ConsumerState<InputOverlay> createState() => _InputOverlayState();
}

class _InputOverlayState extends ConsumerState<InputOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  final _textController = TextEditingController();
  final _textFocus = FocusNode();
  final _textService = const TextInputService();
  String? _textError;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.sheetRise,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideCtrl, curve: AppMotion.sheetRiseCurve));
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _textController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  // ─── Visibility sync ──────────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncVisibility();
  }

  void _syncVisibility() {
    final isVisible = ref.read(inputOverlayProvider).isVisible;
    if (isVisible) {
      _slideCtrl.forward();
    } else {
      _slideCtrl.reverse();
      _textController.clear();
      setState(() => _textError = null);
    }
  }

  // ─── Text submit ──────────────────────────────────────────────────────────

  void _submitText() {
    final outcome = _textService.process(_textController.text);
    if (outcome is TextInputSuccess) {
      _textFocus.unfocus();
      ref
          .read(inputOverlayProvider.notifier)
          .parseInput(outcome.result.rawText);
    } else if (outcome is TextInputError) {
      setState(() => _textError = outcome.message);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final overlayState = ref.watch(inputOverlayProvider);

    // Sync animation when visibility changes
    if (overlayState.isVisible && _slideCtrl.isDismissed) {
      _slideCtrl.forward();
    } else if (!overlayState.isVisible && !_slideCtrl.isDismissed) {
      _slideCtrl.reverse();
      _textController.clear();
    }

    return AnimatedBuilder(
      animation: _slideCtrl,
      builder: (context, child) {
        if (_slideCtrl.isDismissed && !overlayState.isVisible) {
          return const SizedBox.shrink();
        }
        return child!;
      },
      child: Stack(
        children: [
          // ── Blurred backdrop ─────────────────────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              // Tap backdrop = do nothing (prevents accidental close)
              onTap: () {},
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: AppColors.backgroundBot.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),

          // ── Sliding sheet ────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideAnim,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sp4,
                    AppSpacing.sp4,
                    AppSpacing.sp4,
                    AppSpacing.sp6,
                  ),
                  child: overlayState.hasResult
                      ? ConfirmationCard(
                          result: overlayState.parseResult!)
                      : _InputPanel(
                          mode: overlayState.mode,
                          voiceState: overlayState.voiceState,
                          liveTranscript: overlayState.liveTranscript,
                          textController: _textController,
                          textFocus: _textFocus,
                          textError: _textError,
                          onTextChanged: (_) =>
                              setState(() => _textError = null),
                          onSubmitText: _submitText,
                          onSwitchToText: () => ref
                              .read(inputOverlayProvider.notifier)
                              .showText(),
                          onSwitchToVoice: () => ref
                              .read(inputOverlayProvider.notifier)
                              .showVoice(),
                          onClose: () =>
                              ref.read(inputOverlayProvider.notifier).hide(),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Input panel (before parse result) ───────────────────────────────────────

class _InputPanel extends StatelessWidget {
  const _InputPanel({
    required this.mode,
    required this.voiceState,
    required this.liveTranscript,
    required this.textController,
    required this.textFocus,
    required this.textError,
    required this.onTextChanged,
    required this.onSubmitText,
    required this.onSwitchToText,
    required this.onSwitchToVoice,
    required this.onClose,
  });

  final InputMode mode;
  final VoiceState voiceState;
  final String liveTranscript;
  final TextEditingController textController;
  final FocusNode textFocus;
  final String? textError;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onSubmitText;
  final VoidCallback onSwitchToText;
  final VoidCallback onSwitchToVoice;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceL1,
        borderRadius: AppRadius.sheet,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      padding: const EdgeInsets.all(AppSpacing.sp5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top bar: close + mode switch ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onClose,
                child: const Icon(CupertinoIcons.xmark,
                    size: 20, color: AppColors.textTertiary),
              ),
              // Mode toggle
              GestureDetector(
                onTap: mode == InputMode.voice
                    ? onSwitchToText
                    : onSwitchToVoice,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp3, vertical: AppSpacing.sp1),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceL2,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mode == InputMode.voice
                            ? CupertinoIcons.pencil
                            : CupertinoIcons.mic,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sp1),
                      Text(
                        mode == InputMode.voice ? 'Type instead' : 'Use mic',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sp5),

          if (mode == InputMode.voice)
            _VoicePanel(
                voiceState: voiceState, liveTranscript: liveTranscript)
          else
            _TextPanel(
              controller: textController,
              focusNode: textFocus,
              error: textError,
              onChanged: onTextChanged,
              onSubmit: onSubmitText,
            ),

          const SizedBox(height: AppSpacing.sp4),
        ],
      ),
    );
  }
}

// ─── Voice panel ─────────────────────────────────────────────────────────────

class _VoicePanel extends StatelessWidget {
  const _VoicePanel(
      {required this.voiceState, required this.liveTranscript});

  final VoiceState voiceState;
  final String liveTranscript;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live transcript
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.all(AppSpacing.sp3),
          decoration: BoxDecoration(
            color: AppColors.surfaceL2,
            borderRadius: AppRadius.chip,
          ),
          child: liveTranscript.isNotEmpty
              ? Text(liveTranscript,
                  style: AppTypography.body,
                  textAlign: TextAlign.center)
              : Text(
                  voiceState == VoiceState.listening
                      ? 'Listening…'
                      : voiceState == VoiceState.processing
                          ? 'Processing…'
                          : 'Tap the mic to start',
                  style: AppTypography.body
                      .copyWith(color: AppColors.textTertiary),
                  textAlign: TextAlign.center,
                ),
        ),
        const SizedBox(height: AppSpacing.sp5),
        // Mic button (primary)
        const MicButton(),
      ],
    );
  }
}

// ─── Text panel ──────────────────────────────────────────────────────────────

class _TextPanel extends StatelessWidget {
  const _TextPanel({
    required this.controller,
    required this.focusNode,
    required this.error,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? error;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                placeholder: 'e.g. spent 500 on lunch',
                placeholderStyle:
                    AppTypography.body.copyWith(color: AppColors.textTertiary),
                style: AppTypography.body,
                decoration: BoxDecoration(
                  color: AppColors.surfaceL2,
                  borderRadius: AppRadius.chip,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp4, vertical: AppSpacing.sp3),
                onChanged: onChanged,
                onSubmitted: (_) => onSubmit(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: AppSpacing.sp3),
            GestureDetector(
              onTap: onSubmit,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.arrow_up,
                  color: AppColors.backgroundBot,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.sp2),
          Text(error!,
              style:
                  AppTypography.caption.copyWith(color: AppColors.semanticExpense)),
        ],
      ],
    );
  }
}
