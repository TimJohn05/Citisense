import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'models/user_role.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/citizen/citizen_shell.dart';
import 'screens/officer/officer_shell.dart';
import 'services/repository.dart';
import 'state/app_state.dart';
import 'widgets/cs_logo.dart';

class App extends StatelessWidget {
  final AppRepository repository;

  const App({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(repository: repository),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          final highContrast = appState.highContrast;
          final themeMode = appState.themeMode;
          final isDark = themeMode == ThemeMode.dark
              ? true
              : themeMode == ThemeMode.light
                  ? false
                  : MediaQuery.platformBrightnessOf(context) == Brightness.dark;
          AppColors.apply(
            AppPalette.paletteFor(isDark: isDark, highContrast: highContrast),
          );
          return MaterialApp(
            title: 'CitiSense',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeFor(dark: false, highContrast: highContrast),
            darkTheme: AppTheme.themeFor(dark: true, highContrast: highContrast),
            themeMode: themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.isRestoringSession) {
      return const _SessionRestoreSplash();
    }
    if (!appState.isLoggedIn) {
      return const LoginScreen();
    }
    switch (appState.user!.role) {
      case UserRole.citizen:
        return const CitizenShell();
      case UserRole.officer:
        return const OfficerShell();
      case UserRole.admin:
        return const AdminShell();
    }
  }
}

class _SessionRestoreSplash extends StatelessWidget {
  const _SessionRestoreSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CsLogo(size: 72),
            const SizedBox(height: 14),
            Text(
              'CitiSense',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
