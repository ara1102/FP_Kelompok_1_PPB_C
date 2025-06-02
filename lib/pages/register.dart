import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fp_kelompok_1_ppb_c/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

final _formKey = GlobalKey<FormState>();

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorCode = "";

  void navigateLogin() {
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  void navigateHome() {
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, 'home');
  }

  void register() async {
    setState(() {
      _isLoading = true;
      _errorCode = "";
    });

    try {
      await AuthService.instance.registerEmail(
        _emailController.text,
        _passwordController.text,
        _usernameController.text,
      );
      navigateLogin();
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
      appBar: AppBar(title: const Text('Register'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 48),
                Icon(Icons.lock_outline, size: 100, color: Colors.blue[200]),
                const SizedBox(height: 48),
                TextFormField(
                  validator: NameValidator.validate,
                  controller: _usernameController,
                  decoration: const InputDecoration(label: Text('Username')),
                ),
                TextFormField(
                  validator: EmailValidator.validate,
                  controller: _emailController,
                  decoration: const InputDecoration(label: Text('Email')),
                ),
                TextFormField(
                  validator: PasswordValidator.validate,
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
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      register(); // hanya dijalankan jika semua validator lolos
                    }
                  },
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Register'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: navigateLogin,
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
