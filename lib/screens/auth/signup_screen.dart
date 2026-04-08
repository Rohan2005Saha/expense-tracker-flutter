import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
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

  Future<void> _signup() async {
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
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signUp(email: email, password: password);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const HomeScreen(),
        ),
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      final String message = error.code == 'email-already-in-use'
          ? 'Account already exists. Please login instead.'
          : (error.message ?? 'Signup failed');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
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
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign up with email and password to get started.',
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
                autofillHints: const <String>[AutofillHints.newPassword],
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _isLoading ? 'Signing up...' : 'Sign Up',
                onPressed: _isFormReady ? _signup : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
