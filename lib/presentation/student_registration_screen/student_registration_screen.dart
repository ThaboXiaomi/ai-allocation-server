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

  String? _selectedSchool;
  List<String> _selectedCourses = []; // <-- Add this line to hold selected courses
  int? _selectedYear;
  int? _selectedSemester;

  final List<String> _schools = ['SET', 'SOBE', 'SEM'];
  List<String> _courses = [];
  final List<int> _years = [1, 2, 3];
  final Map<int, List<int>> _yearToSemesters = {
    1: [1, 2],
    2: [3, 4],
    3: [5, 6],
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _matricNoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses(String school) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('school', isEqualTo: school)
          .get();
      setState(() {
        _courses = snapshot.docs.map((doc) => doc['courseTitle'] as String).toList();
        _selectedCourses = [];
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to load courses',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSchool == null) {
      Fluttertoast.showToast(
        msg: 'Please select a school',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }
    if (_selectedCourses.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please select at least one course',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }
    if (_selectedYear == null) {
      Fluttertoast.showToast(
        msg: 'Please select year of study',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }
    if (_selectedSemester == null) {
      Fluttertoast.showToast(
        msg: 'Please select semester',
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
        'school': _selectedSchool,
        'courses': _selectedCourses, // Save as a list
        'year': _selectedYear,
        'semester': _selectedSemester,
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
                value: _selectedSchool,
                items: _schools
                    .map((school) => DropdownMenuItem(
                          value: school,
                          child: Row(
                            children: [
                              const Icon(Icons.school, color: Colors.blue), // Material icon
                              const SizedBox(width: 8),
                              Text(school),
                            ],
                          ),
                        ))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Select School',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school), // Material icon
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedSchool = value;
                    _selectedCourses = [];
                    _courses = [];
                  });
                  if (value != null) {
                    _fetchCourses(value);
                  }
                },
                validator: (value) =>
                    value == null ? 'Please select a school' : null,
              ),
              const SizedBox(height: 12),
              // Multi-select for courses
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Select Course(s)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book, color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_courses.isEmpty)
                      const Text('Select a school first'),
                    if (_courses.isNotEmpty)
                      Wrap(
                        spacing: 8.0,
                        children: _courses.map((course) {
                          final selected = _selectedCourses.contains(course);
                          return FilterChip(
                            label: Text(course),
                            selected: selected,
                            onSelected: (bool value) {
                              setState(() {
                                if (value) {
                                  _selectedCourses.add(course);
                                } else {
                                  _selectedCourses.remove(course);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    if (_selectedCourses.isEmpty && _courses.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Please select at least one course',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedYear,
                items: _years
                    .map((year) => DropdownMenuItem(
                          value: year,
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.orange), // Material icon
                              const SizedBox(width: 8),
                              Text('Year $year'),
                            ],
                          ),
                        ))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Year of Study',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today), // Material icon
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value;
                    _selectedSemester = null;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select year of study' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedSemester,
                items: (_selectedYear != null
                        ? _yearToSemesters[_selectedYear] ?? []
                        : <int>[])
                    .map<DropdownMenuItem<int>>((int sem) => DropdownMenuItem<int>(
                          value: sem,
                          child: Row(
                            children: [
                              const Icon(Icons.timelapse, color: Colors.purple), // Material icon
                              const SizedBox(width: 8),
                              Text('Semester $sem'),
                            ],
                          ),
                        ))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timelapse), // Material icon
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedSemester = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select semester' : null,
                disabledHint: const Text('Select year first'),
                isExpanded: true,
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
