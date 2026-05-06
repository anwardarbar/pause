import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/input/voice_input_service.dart';
import '../../../core/providers/input_overlay_provider.dart';
import '../../../core/input/input_result.dart';
import '../../../core/providers/input_providers.dart';
import '../../../core/theme/app_theme.dart';

class MicButton extends ConsumerStatefulWidget {
  const MicButton({super.key});

  @override
  ConsumerState<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends ConsumerState<MicButton>
    with TickerProviderStateMixin {
  late final AnimationController _breatheCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _breatheAnim;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _shakeAnim;

  bool _isHoldMode = false;
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.micBreathe,
    )..repeat(reverse: true);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.micPulse,
    )..repeat(reverse: true);

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _breatheAnim = Tween<double>(begin: 0.08, end: 0.22).animate(
      CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut),
    );
    _pulseAnim = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );

    // Listen to voice service streams
    final service = ref.read(voiceInputServiceProvider);
    service.stateStream.listen(_onVoiceState);
    service.resultStream.listen(_onVoiceResult);
    service.transcriptStream.listen(_onTranscript);
  }

  @override
  void dispose() {
    _vibrationTimer?.cancel();
    _breatheCtrl.dispose();
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ─── Voice stream handlers ────────────────────────────────────────────────

  void _onVoiceState(VoiceState state) {
    // Manage periodic haptic pulse while recording
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    if (state == VoiceState.listening) {
      _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
        HapticFeedback.selectionClick();
      });
    }

    ref.read(inputOverlayProvider.notifier).updateVoiceState(state);
    if (state == VoiceState.error) {
      _shakeCtrl.forward(from: 0);
    }
    if (mounted) setState(() {});
  }

  void _onVoiceResult(InputResult result) {
    ref.read(inputOverlayProvider.notifier).parseInput(result.rawText);
  }

  void _onTranscript(String text) {
    ref.read(inputOverlayProvider.notifier).updateTranscript(text);
  }

  // ─── Gesture handlers ─────────────────────────────────────────────────────

  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (mounted) _showPermissionAlert(permanent: true);
      return false;
    }
    final result = await Permission.microphone.request();
    if (result.isGranted) return true;
    if (mounted) _showPermissionAlert(permanent: result.isPermanentlyDenied);
    return false;
  }

  void _showPermissionAlert({required bool permanent}) {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Microphone Access'),
        content: Text(
          permanent
              ? 'Microphone is disabled. Go to Settings → Pause → Microphone to enable it.'
              : 'Pause needs microphone access to record expenses by voice.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Not Now'),
            onPressed: () => Navigator.pop(context),
          ),
          if (permanent)
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _onTap() async {
    final service = ref.read(voiceInputServiceProvider);
    final state = service.currentState;

    if (state == VoiceState.idle) {
      if (!await _checkPermission()) return;
      // Tap mode — recording until second tap
      _isHoldMode = false;
      ref.read(inputOverlayProvider.notifier).showVoice();
      await service.startListening();
    } else if (state == VoiceState.listening && !_isHoldMode) {
      // Second tap stops recording in tap mode
      await service.stopListening();
    }
  }

  Future<void> _onLongPressStart(LongPressStartDetails _) async {
    final service = ref.read(voiceInputServiceProvider);
    if (service.currentState != VoiceState.idle) return;
    if (!await _checkPermission()) return;
    _isHoldMode = true;
    ref.read(inputOverlayProvider.notifier).showVoice();
    await service.startListening();
  }

  Future<void> _onLongPressEnd(LongPressEndDetails _) async {
    final service = ref.read(voiceInputServiceProvider);
    if (_isHoldMode && service.currentState == VoiceState.listening) {
      await service.stopListening();
    }
    _isHoldMode = false;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final overlayState = ref.watch(inputOverlayProvider);
    final voiceState = overlayState.voiceState;

    return GestureDetector(
      onTap: _onTap,
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breatheAnim, _pulseAnim, _shakeAnim]),
        builder: (context, _) {
          return _buildButton(voiceState);
        },
      ),
    );
  }

  Widget _buildButton(VoiceState voiceState) {
    Color ring1Color;
    Color ring2Color;
    Color iconColor;
    double ring1Opacity;
    double ring2Opacity;
    double glowRadius;
    Color glowColor;

    switch (voiceState) {
      case VoiceState.idle:
        ring1Color = AppColors.goldPrimary;
        ring1Opacity = _breatheAnim.value;
        ring2Color = AppColors.goldPrimary;
        ring2Opacity = _breatheAnim.value * 0.4;
        iconColor = AppColors.goldPrimary;
        glowRadius = 8;
        glowColor = AppColors.goldGlow;
      case VoiceState.listening:
        ring1Color = AppColors.goldHighlight;
        ring1Opacity = _pulseAnim.value;
        ring2Color = AppColors.goldHighlight;
        ring2Opacity = _pulseAnim.value * 0.5;
        iconColor = AppColors.goldHighlight;
        glowRadius = 20;
        glowColor = AppColors.goldGlow;
      case VoiceState.processing:
        ring1Color = AppColors.goldPrimary;
        ring1Opacity = 0;
        ring2Color = AppColors.goldPrimary;
        ring2Opacity = 0;
        iconColor = AppColors.goldPrimary;
        glowRadius = 12;
        glowColor = AppColors.goldGlow;
      case VoiceState.result:
        ring1Color = AppColors.goldPrimary;
        ring1Opacity = 0.15;
        ring2Color = AppColors.goldPrimary;
        ring2Opacity = 0.06;
        iconColor = AppColors.goldPrimary;
        glowRadius = 8;
        glowColor = AppColors.goldGlow;
      case VoiceState.error:
        final shake = sin(_shakeAnim.value * pi * 6) * 0.4;
        ring1Color = AppColors.semanticExpense;
        ring1Opacity = 0.4 + shake.abs() * 0.2;
        ring2Color = AppColors.semanticExpense;
        ring2Opacity = 0;
        iconColor = AppColors.semanticExpense;
        glowRadius = 8;
        glowColor = AppColors.semanticExpense.withValues(alpha: 0.25);
    }

    const buttonSize = 64.0;
    const ring1Size = buttonSize + 24;
    const ring2Size = buttonSize + 48;

    return SizedBox(
      width: ring2Size,
      height: ring2Size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: ring2Size,
            height: ring2Size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ring2Color.withValues(alpha: ring2Opacity),
            ),
          ),
          // Inner ring
          Container(
            width: ring1Size,
            height: ring1Size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ring1Color.withValues(alpha: ring1Opacity),
            ),
          ),
          // Core button
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceL2,
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: glowRadius,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(child: _buildIcon(voiceState, iconColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(VoiceState voiceState, Color color) {
    if (voiceState == VoiceState.processing) {
      return CupertinoActivityIndicator(color: color);
    }

    // Show pause icon when listening in tap mode
    if (voiceState == VoiceState.listening && !_isHoldMode) {
      return Icon(CupertinoIcons.pause_fill, color: color, size: 26);
    }

    return Icon(CupertinoIcons.mic_fill, color: color, size: 26);
  }
}

