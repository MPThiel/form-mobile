import 'package:flutter/material.dart';
import 'core/theme/form_theme.dart';
import 'features/home/presentation/placeholder_home_screen.dart';

class FormApp extends StatelessWidget {
  const FormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FORM',
      debugShowCheckedModeBanner: false,
      theme: FormTheme.dark(),
      darkTheme: FormTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const PlaceholderHomeScreen(),
    );
  }
}
