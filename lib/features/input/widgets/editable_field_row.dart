import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_theme.dart';

/// A tappable label+value row that becomes a [CupertinoTextField] when tapped.
/// Calls [onChanged] on every keystroke and [onDone] when the user dismisses
/// the keyboard. Swipe gestures on the parent card must be disabled while
/// [isEditing] is true.
class EditableFieldRow extends StatefulWidget {
  const EditableFieldRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onDone,
    this.autoFocus = false,
    this.keyboardType = TextInputType.text,
    this.placeholder = '',
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onDone;
  final bool autoFocus;
  final TextInputType keyboardType;
  final String placeholder;

  @override
  State<EditableFieldRow> createState() => _EditableFieldRowState();
}

class _EditableFieldRowState extends State<EditableFieldRow> {
  bool _editing = false;
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) {
        setState(() => _editing = false);
        widget.onDone();
      }
    });
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startEditing());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _editing = true;
      _ctrl.text = widget.value;
      _ctrl.selection =
          TextSelection.collapsed(offset: _ctrl.text.length);
    });
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _editing ? null : _startEditing,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                widget.label,
                style: AppTypography.caption,
              ),
            ),
            Expanded(
              child: _editing
                  ? CupertinoTextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      keyboardType: widget.keyboardType,
                      placeholder: widget.placeholder,
                      style: AppTypography.body,
                      placeholderStyle: AppTypography.body
                          .copyWith(color: AppColors.textTertiary),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceL3,
                        borderRadius: AppRadius.chip,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sp3,
                        vertical: AppSpacing.sp2,
                      ),
                      onChanged: widget.onChanged,
                      onSubmitted: (_) {
                        _focus.unfocus();
                      },
                      textInputAction: TextInputAction.done,
                    )
                  : Text(
                      widget.value.isNotEmpty
                          ? widget.value
                          : widget.placeholder,
                      style: AppTypography.body.copyWith(
                        color: widget.value.isNotEmpty
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
            ),
            if (!_editing)
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.sp2),
                child: Icon(
                  CupertinoIcons.pencil,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
