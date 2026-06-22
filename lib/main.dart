import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const UvIndexApp());
}

class UvIndexApp extends StatelessWidget {
  const UvIndexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UV Index',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
