import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lecture_room_allocator/theme/app_theme.dart';
import 'package:lecture_room_allocator/presentation/student_registration_screen/student_registration_screen.dart';

// Assuming you have a Student Dashboard screen defined somewhere,
// which this screen navigates to upon successful login.
// Make sure your routes are configured correctly, for example in your main.dart
// routes: {
//   '/student-dashboard': (context) => StudentDashboardScreen(),
// }

class StudentAuthScreen extends StatefulWidget {
  const StudentAuthScreen({Key? key}) : super(key: key);

  @override
  State<StudentAuthScreen> createState() => _StudentAuthScreenState();
}

class _StudentAuthScreenState extends State<StudentAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Firebase Authentication logic to sign the user in
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // *** Retrieve the signed-in user object here ***
        User? loggedInUser = userCredential.user;

        // Check if login was successful and we have a user object
        if (loggedInUser != null) {
          print("User logged in successfully!");
          print("User UID: ${loggedInUser.uid}"); // Access the user's unique ID
          print("User Email: ${loggedInUser.email}"); // Access the user's email

          // You can access other properties too, like displayName or photoURL
          // print("Display Name: ${loggedInUser.displayName}");
          // print("Photo URL: ${loggedInUser.photoURL}");

          // You could pass this user object or parts of it to the next screen
          // For example, if your dashboard route accepts arguments:
          // Navigator.pushReplacementNamed(
          //   context,
          //   '/student-dashboard',
          //   arguments: loggedInUser.uid, // or the whole loggedInUser object
          // );

          // Navigate to Student Dashboard if login is successful
          // Using pushReplacementNamed means the user can't go back to the login screen
          // Make sure you have a route named '/student-dashboard' defined in your MaterialApp/CupertinoApp
          Navigator.pushReplacementNamed(context, '/student-dashboard');

        } else {
           // This case is less likely to be hit if signInWithEmailAndPassword
           // completes without an exception, but it's good practice to check.
           print("Login successful, but user object is null?");
            Fluttertoast.showToast(
              msg: "Login failed unexpectedly. Please try again.",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
        }

      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (e.code == 'user-not-found') {
          errorMessage = "No user found for this email.";
        } else if (e.code == 'wrong-password') {
          errorMessage = "Incorrect password. Please try again.";
        } else if (e.code == 'invalid-email') {
           errorMessage = "The email address is not valid.";
        }
        else {
          // Fallback to the Firebase error message if available
          errorMessage = e.message ?? "Login failed. Please try again.";
        }

        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
         print("Firebase Auth Error: ${e.code} - ${e.message}"); // Log the specific error
      } catch (e) {
        // Catch any other unexpected errors during the process
        print("Unexpected login error: $e"); // Print the actual error for debugging
        Fluttertoast.showToast(
          msg: "An unexpected error occurred. Please try again.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } finally {
        // Always stop the loading indicator, even if there's an error
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Portal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary600,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary200,
              AppTheme.primary500,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: AppTheme.primary700,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Student Login',
                    textAlign: TextAlign.center,
                    style:
                        AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          blurRadius: 2.0,
                          color: Colors.black26,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: _emailController,
                    labelText: 'Email or Student ID',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email or student ID';
                      }
                       // Optional: Add basic email format validation
                       // if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                       //   return 'Please enter a valid email address';
                       // }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.primary700,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) => (value?.isEmpty ?? true)
                        ? 'Please enter your password'
                        : null,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.95),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StudentRegistrationScreen()),
                    ),
                    child: Text("Don't have an account? Register",
                        style: TextStyle(color: Colors.white.withOpacity(.9))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: AppTheme.primary700.withOpacity(0.9),
        ),
        prefixIcon: Icon(icon, color: AppTheme.primary700),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
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
      validator: validator,
    );
  }
}
