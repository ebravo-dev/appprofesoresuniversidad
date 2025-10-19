import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'services/database_service.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/utils.dart';
import 'core/theme/uat_theme.dart';
import 'features/authentication/presentation/pages/login_page.dart';
import 'features/groups/screens/grupos_page.dart';
import 'features/authentication/providers/profesor_auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize database
    await DatabaseService().init();
    Logger.info('App initialization completed');
  } catch (e, stackTrace) {
    Logger.error('Error during app initialization', e, stackTrace);
  }

  runApp(const ProviderScope(child: MyApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(profesorAuthProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated ? '/grupos' : '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      // If not authenticated and not on login page, go to login
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // If authenticated and on login page, go to grupos
      if (isAuthenticated && isLoggingIn) {
        return '/grupos';
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/grupos', builder: (context, state) => const GruposPage()),
      GoRoute(
        path: '/dashboard', // Mantener compatibilidad
        redirect: (context, state) => '/grupos',
      ),
      GoRoute(
        path: '/',
        redirect: (context, state) =>
            authState.isAuthenticated ? '/grupos' : '/login',
      ),
    ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: UATTheme.lightTheme,
      routerConfig: router,
    );
  }
}
