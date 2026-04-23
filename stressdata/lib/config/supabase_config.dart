import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://eojegpdmooxwmrqkcich.supabase.co',
      anonKey: 'sb_publishable_l5atLaK61dDLwKs17EABcA_Wrny-rzV',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}