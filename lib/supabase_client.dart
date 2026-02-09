import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://bqsptmtajnovcbvxpxyf.supabase.co',
    anonKey: 'sb_publishable_RIC0U_qqNRr6eeELY7GdlQ_R-iotjqC',
  );
}

SupabaseClient get supabase => Supabase.instance.client;