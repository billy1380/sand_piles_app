import 'package:flutter/material.dart';
import 'package:sand_piles_app/home_page.dart';

class App extends StatelessWidget {
  static final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(0xFF, 0xCC, 0x33, 0xFF),
  );

  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Sand Piles",
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(title: "Sand Piles"),
    );
  }
}
