import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/form_colors.dart';
import '../../../core/theme/form_typography.dart';
import '../providers.dart';

/// Phase 1 sign-in. Magic-link only (Android-first).
///  - Apple Sign-In: deferred to iOS work, intentionally absent.
///  - Google: disabled placeholder, no implementation.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String value) {
    final v = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    ref
        .read(authControllerProvider.notifier)
        .sendMagicLink(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'FORM',
                    textAlign: TextAlign.center,
                    style: FormTypography.data(
                      size: 64,
                      weight: FontWeight.w700,
                      color: FormColors.primary,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'adaptive fitness companion',
                    textAlign: TextAlign.center,
                    style: FormTypography.prose(
                      size: 13,
                      color: FormColors.onSurfaceMuted,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (state is AuthLinkSent)
                    _CheckInbox(email: state.email)
                  else
                    _EmailForm(
                      formKey: _formKey,
                      controller: _emailController,
                      validator: (value) => _looksLikeEmail(value ?? '')
                          ? null
                          : 'Enter a valid email address',
                      onSubmit: _submit,
                      isSending: state is AuthSendingLink,
                      errorMessage: state is AuthFailure ? state.message : null,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailForm extends StatelessWidget {
  const _EmailForm({
    required this.formKey,
    required this.controller,
    required this.validator,
    required this.onSubmit,
    required this.isSending,
    required this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final VoidCallback onSubmit;
  final bool isSending;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: controller,
            enabled: !isSending,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            onFieldSubmitted: (_) => onSubmit(),
            validator: validator,
            style: FormTypography.prose(size: 16),
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: FormTypography.prose(size: 13, color: FormColors.danger),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: isSending ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: FormColors.primary,
              foregroundColor: FormColors.bg,
              disabledBackgroundColor: FormColors.primary.withValues(
                alpha: 0.5,
              ),
              minimumSize: const Size.fromHeight(52),
            ),
            child: isSending
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(FormColors.bg),
                    ),
                  )
                : Text(
                    'Send magic link',
                    style: FormTypography.data(
                      size: 15,
                      weight: FontWeight.w700,
                      color: FormColors.bg,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          const _ComingSoonGoogleButton(),
        ],
      ),
    );
  }
}

/// Disabled Google placeholder. No OAuth wired in Phase 1.
class _ComingSoonGoogleButton extends StatelessWidget {
  const _ComingSoonGoogleButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: null,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: FormColors.border),
        disabledForegroundColor: FormColors.onSurfaceMuted,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              'Continue with Google',
              overflow: TextOverflow.ellipsis,
              style: FormTypography.prose(
                size: 14,
                color: FormColors.onSurfaceMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: FormColors.surfaceHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Coming soon',
              style: FormTypography.data(
                size: 10,
                weight: FontWeight.w600,
                color: FormColors.onSurfaceMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Post-send confirmation state.
class _CheckInbox extends ConsumerWidget {
  const _CheckInbox({required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.mark_email_unread_outlined,
          color: FormColors.secondary,
          size: 48,
        ),
        const SizedBox(height: 20),
        Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: FormTypography.prose(size: 22, weight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            text: 'We sent a magic link to ',
            style: FormTypography.prose(
              size: 14,
              color: FormColors.onSurfaceMuted,
              height: 1.4,
            ),
            children: [
              TextSpan(
                text: email,
                style: FormTypography.prose(
                  size: 14,
                  weight: FontWeight.w600,
                  color: FormColors.onSurface,
                ),
              ),
              const TextSpan(
                text: '. Tap it on this device to finish signing in.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        TextButton(
          onPressed: () =>
              ref.read(authControllerProvider.notifier).backToInput(),
          child: Text(
            'Use a different email',
            style: FormTypography.data(
              size: 14,
              weight: FontWeight.w600,
              color: FormColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
