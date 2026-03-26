import 'package:flutter/material.dart';
import 'package:travel_companion/core/theme/app_theme.dart';
import 'package:travel_companion/features/home/home_screen.dart';

class TravelCompanionApp extends StatelessWidget {
  const TravelCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
