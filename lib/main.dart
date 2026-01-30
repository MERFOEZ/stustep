import 'package:flutter/material.dart';
import 'core/app_colors.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/learning_screen.dart';
import 'screens/branding_screen.dart';
import 'screens/gaming.dart';
import 'screens/courses.dart';

void main() {
  runApp(const StuStepApp());
}

class StuStepApp extends StatelessWidget {
  const StuStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StuStep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto', // Customizing font if available or default
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
      ),
      // For demonstration, we can start with Login or Dashboard
      // Let's start with Dashboard and allow navigation to others for preview
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 5;
  final List<Widget> _screens = [
    const BrandingScreen(),
    const DashboardScreen(),
    const LoginScreen(),
    const LearningScreen(),
    const GamingScreen(),
    const CoursesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _screens.length;
          });
        },
        backgroundColor: AppColors.accentPink,
        child: const Icon(Icons.swap_horiz, color: Colors.white),
      ),
    );
  }
}
