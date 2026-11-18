/// Runtime configuration. Values can be overridden at build time with
/// --dart-define, for example:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
///
/// The Supabase anon key is public by design (row-level security protects
/// the data). Never put Gemini or service-role keys in the app.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vjbhmyyeqenlypyqufgd.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqYmhteXllcWVubHlweXF1ZmdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4MjU3ODQsImV4cCI6MjA5MzQwMTc4NH0.WoMAmiDnaEFs-Ad_WuX37tHlajGSQIAdxv2jf6X2eU4',
  );

  /// Base URL of the FastAPI backend (buddy chat). Empty means "use the
  /// default for this platform" (10.0.2.2 on the Android emulator, localhost otherwise).
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
}
