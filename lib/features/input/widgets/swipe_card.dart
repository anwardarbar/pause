import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Wraps [child] with horizontal swipe gestures for confirm/discard.
///
/// Right swipe  → green glow overlay → [onConfirm] when past threshold
/// Left swipe   → red glow overlay   → [onDiscard] when past threshold
/// Down swipe   → [onDiscard]
/// Backdrop tap → snap back (set by parent via [GestureDetector] wrapping)
///
/// Swipe is disabled when [swipeEnabled] is false (while a field is editing).
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.child,
    required this.onConfirm,
    required this.onDiscard,
    this.swipeEnabled = true,
  });

  final Widget child;
  final VoidCallback onConfirm;
  final VoidCallback onDiscard;
  final bool swipeEnabled;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _snapCtrl;
  late Animation<Offset> _snapAnim;

  double _dragX = 0;
  double _cardWidth = 0;
  bool _thresholdHapticFired = false;
  bool _dismissing = false;

  static const _threshold = 0.5; // 50% of card width
  static const _dismissMultiplier = 3.0;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.swipeSnap,
    );
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  double get _dragPercent =>
      _cardWidth > 0 ? (_dragX / (_cardWidth * _threshold)).clamp(-1.0, 1.0) : 0;

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.swipeEnabled || _dismissing) return;
    setState(() => _dragX += details.delta.dx);

    // Haptic at threshold
    if (!_thresholdHapticFired && _dragPercent.abs() >= 1.0) {
      HapticFeedback.lightImpact();
      _thresholdHapticFired = true;
    }
    if (_dragPercent.abs() < 1.0) _thresholdHapticFired = false;
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.swipeEnabled || _dismissing) return;

    if (_dragPercent >= 1.0) {
      _dismiss(toRight: true);
    } else if (_dragPercent <= -1.0) {
      _dismiss(toRight: false);
    } else {
      _snapBack();
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!widget.swipeEnabled || _dismissing) return;
    if (details.velocity.pixelsPerSecond.dy > 200) {
      widget.onDiscard();
    }
  }

  void _dismiss({required bool toRight}) {
    _dismissing = true;
    final targetX = toRight
        ? _cardWidth * _dismissMultiplier
        : -_cardWidth * _dismissMultiplier;

    _snapAnim = Tween<Offset>(
      begin: Offset(_dragX, 0),
      end: Offset(targetX, 0),
    ).animate(CurvedAnimation(
        parent: _snapCtrl, curve: AppMotion.swipeDismissCurve));

    _snapCtrl.forward(from: 0).then((_) {
      if (toRight) {
        widget.onConfirm();
      } else {
        widget.onDiscard();
      }
    });
  }

  void _snapBack() {
    _snapAnim = Tween<Offset>(
      begin: Offset(_dragX, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _snapCtrl, curve: AppMotion.swipeSnapCurve));

    _snapCtrl.forward(from: 0).then((_) {
      setState(() {
        _dragX = 0;
        _dismissing = false;
      });
    });
  }

  Color get _glowColor {
    if (_dragPercent > 0) {
      return CupertinoColors.systemGreen
          .withValues(alpha: _dragPercent * 0.35);
    } else if (_dragPercent < 0) {
      return AppColors.semanticExpense
          .withValues(alpha: _dragPercent.abs() * 0.35);
    }
    return const Color(0x00000000);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _cardWidth = constraints.maxWidth;

      return GestureDetector(
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: AnimatedBuilder(
          animation: _snapCtrl,
          builder: (context, child) {
            final offset = _snapCtrl.isAnimating
                ? _snapAnim.value.dx
                : _dragX;

            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: Stack(
            children: [
              widget.child,
              // Glow overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _snapCtrl,
                    builder: (_, __) => Container(
                      decoration: BoxDecoration(
                        color: _glowColor,
                        borderRadius: AppRadius.sheet,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
