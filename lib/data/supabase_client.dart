import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Call once, before runApp. After that, use `supabase` anywhere in the app.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
