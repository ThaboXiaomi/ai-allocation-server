import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lecture_room_allocator/theme/app_theme.dart';
import 'package:lecture_room_allocator/presentation/admin_registration_screen/admin_registration_screen.dart';
import 'package:lecture_room_allocator/presentation/admin_password_reset/admin_password_reset.dart';

class AdminAuthScreen extends StatefulWidget {
  const AdminAuthScreen({Key? key}) : super(key: key);

  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1️⃣ Sign in with Firebase Auth
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      final user = cred.user!;
      
      // 2️⃣ Verify admin role in Firestore (read from 'admins' collection)
      final doc = await FirebaseFirestore.instance
          .collection('admins')      // ← here!
          .doc(user.uid)
          .get();

      if (doc.exists) {
        // ✅ Success: go to admin dashboard
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        await FirebaseAuth.instance.signOut();
        Fluttertoast.showToast(
          msg: 'You do not have admin privileges.',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No user found for this email.';
          break;
        case 'wrong-password':
          msg = 'Incorrect password.';
          break;
        case 'invalid-email':
          msg = 'The email address is not valid.';
          break;
        default:
          msg = e.message ?? 'Login failed. Please try again.';
      }
      Fluttertoast.showToast(msg: msg, backgroundColor: Colors.red, toastLength: Toast.LENGTH_LONG);
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An unexpected error occurred. Please try again.',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      debugPrint('Unexpected login error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Portal', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary600,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary200, AppTheme.primary500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.admin_panel_settings, size: 80, color: AppTheme.primary700),
                  const SizedBox(height: 20),
                  Text('Admin Login',
                      textAlign: TextAlign.center,
                      style: AppTheme.lightTheme.textTheme.headlineMedium!
                          .copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 2,
                                color: Colors.black.withOpacity(.3),
                                offset: const Offset(1, 1),
                              )
                            ],
                          )),
                  const SizedBox(height: 40),

                  // Email Field
                  _buildField(
                    controller: _emailCtrl,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please enter your email';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  _buildField(
                    controller: _passCtrl,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.primary700,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) => (v ?? '').length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 30),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(.95),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text('Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary700,
                            )),
                  ),
                  const SizedBox(height: 10),

                  // Register Link
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminRegistrationScreen(),
                      ),
                    ),
                    child: Text(
                      "Don't have an account? Register",
                      style: TextStyle(color: Colors.white.withOpacity(.9)),
                    ),
                  ),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminPasswordResetPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: AppTheme.primary700.withOpacity(.9)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.primary700.withOpacity(.9)),
        prefixIcon: Icon(icon, color: AppTheme.primary700),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary700, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        ),
      ),
      style: const TextStyle(color: Colors.black87),
    );
  }
}
