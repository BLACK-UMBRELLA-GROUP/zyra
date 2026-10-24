import 'package:flutter/material.dart';

import '../theme/zyra_colors.dart';
import '../theme/zyra_text.dart';

/// An open, centred name entry rather than a card inside a question card.
/// The owning signup flow still validates, saves and advances this answer.
class ZyraOnboardingNameField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool lastName;
  final TextInputAction textInputAction;

  const ZyraOnboardingNameField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.lastName = false,
    this.textInputAction = TextInputAction.done,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: TextField(
      key: ValueKey(
        lastName ? 'onboarding_last_name' : 'onboarding_first_name',
      ),
      controller: controller,
      onChanged: onChanged,
      onSubmitted: (_) {
        // EditableText already traverses once for Next. Traversing again here
        // would skip the surname field. Done dismisses only; it never advances.
        if (textInputAction != TextInputAction.next) {
          FocusScope.of(context).unfocus();
        }
      },
      textAlign: TextAlign.center,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      textInputAction: textInputAction,
      autofillHints: [
        lastName ? AutofillHints.familyName : AutofillHints.givenName,
      ],
      autocorrect: false,
      enableSuggestions: false,
      maxLength: 60,
      style: ZyraText.body(size: 28, color: ZyraColors.foreground),
      cursorColor: ZyraColors.splashWordmark,
      decoration: InputDecoration(
        hintText: lastName ? 'Last name' : 'First name',
        hintStyle: ZyraText.body(size: 28, color: ZyraColors.ink(0.46)),
        filled: false,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: ZyraColors.splashWordmark.withValues(alpha: 0.34),
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: ZyraColors.splashWordmark.withValues(alpha: 0.34),
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: ZyraColors.splashWordmark, width: 1.25),
        ),
      ),
    ),
  );
}
