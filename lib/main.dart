import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'expense_tracker_screen.dart';
import 'login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rkwhdydmslnylirehmlg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJrd2hkeWRtc2xueWxpcmVobWxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI0OTc4NDAsImV4cCI6MjA5ODA3Mzg0MH0.rkumwlfgEpmE-snQ-BW7hxQowMiIrWF80ollmwFFWDM',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Expensio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: session != null ? const ExpenseTrackerScreen() : const LoginScreen(),
    );
  }
}
