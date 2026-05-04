import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://vjbhmyyeqenlypyqufgd.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqYmhteXllcWVubHlweXF1ZmdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4MjU3ODQsImV4cCI6MjA5MzQwMTc4NH0.WoMAmiDnaEFs-Ad_WuX37tHlajGSQIAdxv2jf6X2eU4',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}