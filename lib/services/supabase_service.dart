import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/runner.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get all runners
  static Future<List<Runner>> getAllRunners() async {
    try {
      final response = await _client
          .from(SupabaseConfig.runnersTable)
          .select()
          .eq('is_active', true)
          .neq('name', '')
          .neq('bib', '')
          .order('cp9', ascending: true);
      
      return response.map((json) => Runner.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching runners: $e');
      return [];
    }
  }

  // Get runners by gender
  static Future<List<Runner>> getRunnersByGender(String gender) async {
    try {
      final response = await _client
          .from(SupabaseConfig.runnersTable)
          .select()
          .eq('is_active', true)
          .eq('gender', gender)
          .neq('name', '')
          .neq('bib', '')
          .order('cp9', ascending: true);
      
      return response.map((json) => Runner.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching runners by gender: $e');
      return [];
    }
  }

  // Get runners by category
  static Future<List<Runner>> getRunnersByCategory(String category) async {
    try {
      final response = await _client
          .from(SupabaseConfig.runnersTable)
          .select()
          .eq('is_active', true)
          .eq('category', category)
          .neq('name', '')
          .neq('bib', '')
          .order('cp9', ascending: true);
      
      return response.map((json) => Runner.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching runners by category: $e');
      return [];
    }
  }

  // Get real-time updates
  static RealtimeChannel subscribeToRunners() {
    return _client
        .channel(SupabaseConfig.runnersChannel)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConfig.runnersTable,
          callback: (payload) {
            print('Real-time update: $payload');
          },
        )
        .subscribe();
  }
}
