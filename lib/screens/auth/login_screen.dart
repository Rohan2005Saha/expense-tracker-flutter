import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_refreshState);
    _passwordController.addListener(_refreshState);
  }

  @override
  void dispose() {
    _emailController.removeListener(_refreshState);
    _passwordController.removeListener(_refreshState);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _refreshState() {
    setState(() {});
  }

  bool get _isFormReady {
    return _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        !_isLoading;
  }

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signIn(
        context,
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      if (result == null) {
        return;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Login to continue managing your expenses.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                autofillHints: const <String>[AutofillHints.password],
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _isLoading ? 'Logging in...' : 'Login',
                onPressed: _isFormReady ? _login : null,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pushNamed(context, '/signup'),
                  child: const Text("Don't have an account? Sign up"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
