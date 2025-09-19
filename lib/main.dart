import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/tabbed_results_screen.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  runApp(const ResultPatriotApp());
}

class ResultPatriotApp extends StatelessWidget {
  const ResultPatriotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patriot Race Results',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const TabbedResultsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
