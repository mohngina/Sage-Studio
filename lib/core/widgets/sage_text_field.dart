import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';
import '../theme/typography.dart';

/// Form field matching the existing contact-form styling (uppercase label,
/// underline input, burnt-orange focus) with validation support.
class SageTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const SageTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onSubmitted,
    this.inputFormatters,
  });

  @override
  State<SageTextField> createState() => _SageTextFieldState();
}

class _SageTextFieldState extends State<SageTextField> {
  late bool _hidden = widget.obscure;

  @override
  void didUpdateWidget(covariant SageTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscure != widget.obscure) {
      _hidden = widget.obscure;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTypography.labelUppercase()),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: widget.obscure && _hidden,
          enableSuggestions: !widget.obscure,
          autocorrect: !widget.obscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          onFieldSubmitted: widget.onSubmitted,
          inputFormatters: widget.inputFormatters,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: AppTypography.bodyLarge(),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.bodyMedium(color: DesignTokens.textMuted),
            errorStyle: AppTypography.bodySmall(color: DesignTokens.galleryAccent),
            errorMaxLines: 3,
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: DesignTokens.borderLight)),
            focusedBorder:
                const UnderlineInputBorder(borderSide: BorderSide(color: DesignTokens.burntOrange, width: 1.5)),
            errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: DesignTokens.galleryAccent)),
            focusedErrorBorder:
                const UnderlineInputBorder(borderSide: BorderSide(color: DesignTokens.galleryAccent, width: 1.5)),
            disabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: DesignTokens.borderLight)),
            suffixIcon: widget.obscure
                ? IconButton(
                    tooltip: _hidden ? 'Show password' : 'Hide password',
                    icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18, color: DesignTokens.textMuted),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
