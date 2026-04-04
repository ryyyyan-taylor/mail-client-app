import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/providers.dart';
import 'ui/auth/sign_in_screen.dart';
import 'ui/inbox/inbox_screen.dart';
import 'ui/thread/thread_detail_screen.dart';

// Route name constants — use these instead of raw strings.
abstract final class Routes {
  static const splash = '/';
  static const signIn = '/signin';
  static const inbox = '/inbox';
  static String thread(String id) => '/thread/$id';
}

final appRouter = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(
      path: Routes.splash,
      builder: (context, state) => const _SplashScreen(),
    ),
    GoRoute(
      path: Routes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: Routes.inbox,
      builder: (context, state) => InboxScreen(
        initialSelectedThreadId: state.uri.queryParameters['initialThread'],
      ),
    ),
    GoRoute(
      path: '/thread/:id',
      pageBuilder: (context, state) {
        final threadId = state.pathParameters['id']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ThreadDetailScreen(threadId: threadId),
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurveTween(curve: Curves.easeIn).animate(animation),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(
                  CurveTween(curve: Curves.easeOut).animate(animation)),
              child: child,
            ),
          ),
        );
      },
    ),
  ],
);

// Splash — checks auth state then routes to inbox or sign-in.
class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isSignedIn = await ref.read(authRepositoryProvider).isSignedIn();
    if (!mounted) return;

    if (!isSignedIn) {
      context.go(Routes.signIn);
      return;
    }

    // Check if the app was launched by tapping a notification.
    final launchDetails =
        await FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails();
    if (!mounted) return;

    final threadId = launchDetails?.didNotificationLaunchApp == true
        ? launchDetails?.notificationResponse?.payload
        : null;

    if (threadId != null) {
      final isLandscape =
          MediaQuery.orientationOf(context) == Orientation.landscape;
      if (isLandscape) {
        context.go(
            '${Routes.inbox}?initialThread=${Uri.encodeComponent(threadId)}');
      } else {
        context.go(Routes.thread(threadId));
      }
    } else {
      context.go(Routes.inbox);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Color(0xFF000000));
  }
}
