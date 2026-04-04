import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../router.dart';
import '../theme/colors.dart';
import 'sign_in_notifier.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Navigate to inbox after a successful sign-in attempt.
    ref.listen<AsyncValue<void>>(signInNotifierProvider, (previous, next) {
      if (previous is AsyncLoading && next is AsyncData) {
        context.go(Routes.inbox);
      }
    });

    final state = ref.watch(signInNotifierProvider);
    final isLoading = state is AsyncLoading;
    final error = state is AsyncError ? state.error.toString() : null;

    return Scaffold(
      backgroundColor: kBlack,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Text(
              'mail',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w300,
                    fontSize: 52,
                  ),
            ),
            Transform.translate(
              offset: const Offset(0, -14),
              child: Text(
                'client',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: kAccent,
                      fontWeight: FontWeight.w300,
                      fontSize: 52,
                    ),
              ),
            ),

            const SizedBox(height: 58), // 72 - 14 absorbed by the offset above

            // Sign-in button / loading indicator
            if (isLoading)
              const CircularProgressIndicator(color: kAccent)
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => ref.read(signInNotifierProvider.notifier).signIn(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kTextPrimary,
                    side: const BorderSide(color: kDivider),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Sign in with Google',
                      style: TextStyle(fontSize: 15)),
                ),
              ),

            // Error message
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(
                error,
                style: const TextStyle(color: kDanger, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
