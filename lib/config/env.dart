import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static String get supabaseUrl {
    final value = dotenv.env['SUPABASE_URL'];

    if (value == null || value.isEmpty) {
      throw Exception('SUPABASE_URL is not configured.');
    }

    return value;
  }

  static String get supabaseAnonKey {
    final value = dotenv.env['SUPABASE_ANON_KEY'];

    if (value == null || value.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY is not configured.');
    }

    return value;
  }
}
