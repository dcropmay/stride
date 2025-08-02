import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _auth = AuthService();

  String? _error;
  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (_emailCtrl.text.trim().isEmpty || _pwdCtrl.text.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = "Email and password can't be empty.";
      });
      return;
    }

    final err = await _auth.signIn(_emailCtrl.text.trim(), _pwdCtrl.text);
    setState(() => _isLoading = false);

    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00796B), Color(0xFF004D40)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 100,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Track your strides with confidence!',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00796B),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_error != null)
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _emailCtrl,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _pwdCtrl,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00796B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      letterSpacing: 1.2,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Don’t have an account? Register',
                            style: TextStyle(
                              color: Color(0xFF00796B),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
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
