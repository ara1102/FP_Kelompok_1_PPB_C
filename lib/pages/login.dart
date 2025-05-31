import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorCode = "";

  void navigateRegister() {
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, 'register');
  }

  void navigateHome() {
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, 'home');
  }

  void signIn() async {
    setState(() {
      _isLoading = true;
      _errorCode = "";
    });

    try {
      await AuthService.instance.loginEmail(_emailController.text, _passwordController.text);
      navigateHome();
    } catch (e) {
      if (e is FirebaseAuthException) {
        setState(() {
          _errorCode = e.message ?? "An error occurred. Please try again.";
        });
      } else {
        setState(() {
          _errorCode = "An unexpected error occurred.";
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ListView(
            children: [
              const SizedBox(height: 48),
              Icon(Icons.lock_outline, size: 100, color: Colors.blue[200]),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(label: Text('Email')),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(label: Text('Password')),
              ),
              const SizedBox(height: 24),
              _errorCode != ""
                  ? Column(
                    children: [Text(_errorCode), const SizedBox(height: 24)],
                  )
                  : const SizedBox(height: 0),
              OutlinedButton(
                onPressed: signIn,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Login'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account?'),
                  TextButton(
                    onPressed: navigateRegister,
                    child: const Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
