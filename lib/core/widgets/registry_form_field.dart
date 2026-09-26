import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:the_registry/app/theme/app_colors.dart';
import 'package:the_registry/app/theme/app_radius.dart';
import 'package:the_registry/app/theme/app_spacing.dart';

/// Shared Aura field chrome: persistent label above a filled, rounded surface.
abstract final class RegistryFieldStyle {
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: 15,
  );

  static Color fill(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? scheme.surfaceContainerHighest
        : AppColors.inputFill;
  }

  static Color border(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? scheme.outline
        : AppColors.inputBorder;
  }

  static Color focus(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.tertiary
        : AppColors.inputFocus;
  }

  static OutlineInputBorder borderShape(BuildContext context, {Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: color ?? border(context)),
    );
  }

  static InputDecoration decoration(
    BuildContext context, {
    String? hintText,
    String? errorText,
    String? helperText,
    Widget? suffixIcon,
    Widget? prefixIcon,
    BoxConstraints? suffixIconConstraints,
    bool enabled = true,
    bool error = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.input);
    final idle = error ? scheme.error : border(context);
    final active = error ? scheme.error : focus(context);
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      errorMaxLines: 4,
      helperText: helperText,
      helperMaxLines: 4,
      filled: true,
      fillColor: enabled ? fill(context) : scheme.surfaceContainer,
      suffixIcon: suffixIcon,
      suffixIconConstraints: suffixIconConstraints,
      prefixIcon: prefixIcon,
      contentPadding: contentPadding,
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: idle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: idle),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: active, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.error, width: 1.6),
      ),
    );
  }
}

class RegistryFieldLabel extends StatelessWidget {
  const RegistryFieldLabel({
    super.key,
    required this.label,
    this.requiredField = false,
  });

  final String label;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = requiredField ? '$label *' : label;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 6),
      child: Text(
        shown,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class RegistryLabeledField extends StatelessWidget {
  const RegistryLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.requiredField = false,
    this.errorText,
    this.helperText,
    this.footer,
  });

  final String label;
  final Widget child;
  final bool requiredField;
  final String? errorText;
  final String? helperText;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistryFieldLabel(label: label, requiredField: requiredField),
        child,
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(helperText!, style: theme.textTheme.bodySmall),
        ],
        if (footer != null) ...[const SizedBox(height: 6), footer!],
      ],
    );
  }
}

class RegistryTextField extends StatelessWidget {
  const RegistryTextField({
    super.key,
    required this.label,
    this.controller,
    this.fieldKey,
    this.onChanged,
    this.errorText,
    this.helperText,
    this.hintText,
    this.requiredField = false,
    this.enabled = true,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.enableIMEPersonalizedLearning = true,
    this.suffixIcon,
    this.prefixIcon,
    this.suffixIconConstraints,
    this.inputFormatters,
    this.focusNode,
    this.onSubmitted,
    this.footer,
    this.scrollPadding = AppSpacing.wizardFieldScrollPadding,
  });

  final String label;
  final TextEditingController? controller;
  final Key? fieldKey;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? helperText;
  final String? hintText;
  final bool requiredField;
  final bool enabled;
  final bool obscureText;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool enableIMEPersonalizedLearning;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final BoxConstraints? suffixIconConstraints;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final Widget? footer;
  final EdgeInsets scrollPadding;

  @override
  Widget build(BuildContext context) {
    final multiline = (maxLines ?? 1) > 1 || minLines != null;
    return RegistryLabeledField(
      label: label,
      requiredField: requiredField,
      errorText: errorText,
      helperText: helperText,
      footer: footer,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: multiline
              ? AppSpacing.inputHeight
              : AppSpacing.inputHeight,
        ),
        child: TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          textInputAction:
              textInputAction ??
              (multiline ? TextInputAction.newline : TextInputAction.next),
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
          inputFormatters: inputFormatters,
          scrollPadding: scrollPadding,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: RegistryFieldStyle.decoration(
            context,
            hintText: hintText,
            suffixIcon: suffixIcon,
            suffixIconConstraints: suffixIconConstraints,
            prefixIcon: prefixIcon,
            enabled: enabled,
            error: errorText != null,
          ),
        ),
      ),
    );
  }
}

class RegistryFieldSurface extends StatelessWidget {
  const RegistryFieldSurface({
    super.key,
    required this.child,
    this.focused = false,
    this.enabled = true,
    this.error = false,
    this.onTap,
    this.minHeight = AppSpacing.inputHeight,
  });

  final Widget child;
  final bool focused;
  final bool enabled;
  final bool error;
  final VoidCallback? onTap;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = error
        ? scheme.error
        : focused
        ? RegistryFieldStyle.focus(context)
        : RegistryFieldStyle.border(context);
    final fill = enabled
        ? RegistryFieldStyle.fill(context)
        : scheme.surfaceContainer;

    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        side: BorderSide(color: borderColor, width: focused ? 1.6 : 1),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: RegistryFieldStyle.contentPadding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class RegistryWizardProgress extends StatelessWidget {
  const RegistryWizardProgress({
    super.key,
    required this.current,
    required this.total,
    this.label,
    this.labelKey,
  });

  final int current;
  final int total;
  final String? label;
  final Key? labelKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.tertiary;
    final track = const Color(0xFFE4E1F2);
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i != 0) const SizedBox(width: 4),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: SizedBox(
                      height: 4,
                      child: ColoredBox(color: i < current ? accent : track),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 10),
          Text(
            label!,
            key: labelKey,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class RegistryExpandableSection extends StatelessWidget {
  const RegistryExpandableSection({
    super.key,
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.subtitle,
    this.icon,
    this.toggleKey,
  });

  final String title;
  final String? subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final IconData? icon;
  final Key? toggleKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistryFieldSurface(
          key: toggleKey,
          onTap: onToggle,
          minHeight: AppSpacing.minTapTarget,
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        if (expanded) child,
      ],
    );
  }
}
