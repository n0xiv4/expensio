import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  // 1. Ensures Flutter framework is completely ready before we start async operations
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Supabase (Replace with your actual URL and Anon Key from supabase.com)
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
    return MaterialApp(
      title: 'Expensio',
      debugShowCheckedModeBanner: false, // Removes the red debug banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), // Expensio Theme!
        useMaterial3: true,
      ),
      home: const LoginScreen(), // Directs the app to start on your Login Screen
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // sign up
  void _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter email and password')));
      return;
    }

    final response = await _authService.signUpWithEmail(email, password);

    if (response != null && response.user != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created! You can now log in.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign up failed.')));
    }
  }

  // login
  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await _authService.signInWithEmail(email, password);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome back!'), backgroundColor: Colors.green),
      );
      // TODO: Navigator.pushReplacement(...) - go to next screen
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Expensio'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Authentication', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)), obscureText: true),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _handleLogin, child: const Text('Login')),
            const SizedBox(height: 10),
            TextButton(onPressed: _handleSignUp, child: const Text('Create New Account')),
          ],
        ),
      ),
    );
  }
}