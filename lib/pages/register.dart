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
      backgroundColor: const Color(0xFFFFC760), // Orange color from the image
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 48),
                Image.asset('images/simplified.png', height: 100),
                const SizedBox(height: 24),
                const Text(
                  'REGISTER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333), // Dark color from the image
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  validator: NameValidator.validate,
                  controller: _usernameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.badge,
                    ), // Changed to badge for Blaabber ID
                    labelText: 'Blaabber ID',
                    labelStyle: const TextStyle(color: Color(0xFF333333)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Color(0xFF333333)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Color(0xFF333333)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Color(0xFF333333)),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Added spacing between text fields
                TextFormField(
                  validator: EmailValidator.validate,
                  controller: _emailController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person),
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Color(0xFF333333)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Color(0xFF333333)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Color(0xFF333333)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Color(0xFF333333)),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Added spacing between text fields
                TextFormField(
                  validator: PasswordValidator.validate,
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Color(0xFF333333)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Color(0xFF333333)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Color(0xFF333333)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Color(0xFF333333)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _errorCode != ""
                    ? Column(
                      children: [Text(_errorCode), const SizedBox(height: 24)],
                    )
                    : const SizedBox(height: 0),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      register(); // hanya dijalankan jika semua validator lolos
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF333333,
                    ), // Dark color from the image
                    foregroundColor: Colors.white,
                    minimumSize: const Size(
                      double.infinity,
                      50,
                    ), // Full width, 50 height
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('REGISTER'),
                ),
                const SizedBox(height: 16), // Spacing before the "LOGIN?" text
                TextButton(
                  onPressed: navigateLogin,
                  child: const Text(
                    'LOGIN?',
                    style: TextStyle(
                      color: Color(0xFF333333), // Dark color from the image
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
