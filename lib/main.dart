import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/theme_controller.dart';
import 'firebase_options.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/budget/add_budget_screen.dart';
import 'screens/expense/add_expense_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAuth.instance;
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  static ExpenseTrackerAppState of(BuildContext context) {
    final ExpenseTrackerAppState? state = context
        .findAncestorStateOfType<ExpenseTrackerAppState>();
    assert(state != null, 'ExpenseTrackerApp state not found in context');
    return state!;
  }

  @override
  State<ExpenseTrackerApp> createState() => ExpenseTrackerAppState();
}

class ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  final ThemeController _themeController = ThemeController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  Future<void> toggleThemeMode() async {
    await _themeController.toggleThemeMode();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0F766E);
    const Color surfaceColor = Color(0xFFF7F9FC);
    const Color cardColor = Colors.white;
    const Color darkSurfaceColor = Color(0xFF0F172A);
    const Color darkCardColor = Color(0xFF111827);
    final ColorScheme lightColorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      surface: cardColor,
      brightness: Brightness.light,
    );
    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: const Color(0xFF2DD4BF),
      surface: darkCardColor,
      brightness: Brightness.dark,
    );

    return AnimatedBuilder(
      animation: _themeController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Expense Tracker',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/add-expense': (context) => const AddExpenseScreen(),
            '/add-budget': (context) => const AddBudgetScreen(),
            '/analytics': (context) => const AnalyticsScreen(),
          },
          home: AuthWrapper(authService: _authService),
          themeMode: _themeController.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            scaffoldBackgroundColor: surfaceColor,
            cardColor: cardColor,
            textTheme: const TextTheme(
              headlineMedium: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: Color(0xFF111827),
              ),
              titleLarge: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Color(0xFF111827),
              ),
              titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                height: 1.45,
                color: Color(0xFF374151),
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF4B5563),
              ),
              labelLarge: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            appBarTheme: AppBarTheme(
              centerTitle: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: cardColor,
              foregroundColor: const Color(0xFF111827),
              titleTextStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                side: BorderSide(color: lightColorScheme.outlineVariant),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: lightColorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: lightColorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: primaryColor, width: 1.4),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
            scaffoldBackgroundColor: darkSurfaceColor,
            cardColor: darkCardColor,
            textTheme: const TextTheme(
              headlineMedium: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: Color(0xFFF8FAFC),
              ),
              titleLarge: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Color(0xFFF8FAFC),
              ),
              titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE5E7EB),
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                height: 1.45,
                color: Color(0xFFD1D5DB),
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFFCBD5E1),
              ),
              labelLarge: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: darkCardColor,
              foregroundColor: Color(0xFFF8FAFC),
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF8FAFC),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: const Color(0xFF062C2A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                side: BorderSide(color: darkColorScheme.outlineVariant),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF14B8A6),
              foregroundColor: Color(0xFF062C2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1F2937),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: darkColorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: darkColorScheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFF2DD4BF),
                  width: 1.4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
