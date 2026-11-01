import 'package:flutter/material.dart';
import 'data/gparc_database.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GparcDatabase.instance.initialize();
  runApp(const GparcApp());
}

class GparcApp extends StatelessWidget {
  const GparcApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'GParc Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF145A8D)),
          appBarTheme: const AppBarTheme(centerTitle: false),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        home: const HomeScreen(),
      );
}
