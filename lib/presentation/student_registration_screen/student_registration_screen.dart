import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _matricNoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  String? _selectedCourse;

  final List<String> _courses = ['SET', 'SOBE', 'SEM'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _matricNoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourse == null) {
      Fluttertoast.showToast(
        msg: 'Please select a course',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    setState(() => _isLoading = true);

    UserCredential? userCredential;
    try {
      userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
          );
      debugPrint('✅ Auth user created: ${userCredential.user!.uid}');
    } on FirebaseAuthException catch (e, st) {
      debugPrint('🔴 FirebaseAuthException: $e\n$st');
      Fluttertoast.showToast(
        msg: e.message ?? 'Authentication failed',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      setState(() => _isLoading = false);
      return;
    } catch (e, st) {
      debugPrint('🔴 Unknown error during Auth: $e\n$st');
      Fluttertoast.showToast(
        msg: e.toString(),
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final uid = userCredential!.user!.uid;
      await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .set({
        'uid': uid,
        'name': _nameCtrl.text.trim(),
        'matricNo': _matricNoCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'course': _selectedCourse,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Firestore write succeeded for $uid');

      Fluttertoast.showToast(
        msg: 'Registration successful!',
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );
      Navigator.pop(context);
    } on FirebaseException catch (e, st) {
      debugPrint('🔴 FirebaseException (Firestore): $e\n$st');
      Fluttertoast.showToast(
        msg: e.message ?? 'Database error',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e, st) {
      debugPrint('🔴 Unknown error during Firestore write: $e\n$st');
      Fluttertoast.showToast(
        msg: e.toString(),
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Registration')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField(
                controller: _nameCtrl,
                label: 'Full Name',
                validator: (v) => v!.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _matricNoCtrl,
                label: 'Matric Number',
                validator: (v) => v!.isEmpty ? 'Enter matric number' : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _emailCtrl,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v!.isEmpty || !v.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _passCtrl,
                label: 'Password',
                obscure: _obscure,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCourse,
                items: _courses
                    .map((course) => DropdownMenuItem(
                          value: course,
                          child: Text(course),
                        ))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Select Course',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedCourse = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a course' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Register',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
