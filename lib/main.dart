import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'layar_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hqdihfmxygxzqmxgfgsr.supabase.co',
    anonKey: 'sb_publishable_P1rQSJcxdlJMDP45pS_DwA_jWdjA12Z',
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriBox',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), 
        useMaterial3: true,
      ),
      home: const LayarAuth(), 
    );
  }
}
