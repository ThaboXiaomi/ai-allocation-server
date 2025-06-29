import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentSettings extends StatefulWidget {
  const StudentSettings({Key? key}) : super(key: key);

  @override
  State<StudentSettings> createState() => _StudentSettingsState();
}

class _StudentSettingsState extends State<StudentSettings> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _programController = TextEditingController();
  final _yearController = TextEditingController();
  final _semesterController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> _availableCourses = [];
  List<String> _selectedCourseCodes = [];

  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('courses').get();
      setState(() {
        _availableCourses = snapshot.docs
            .map((doc) => {
                  'courseCode': doc['courseCode'],
                  'courseTitle': doc['courseTitle'],
                  'school': doc['school'],
                })
            .toList();
      });
    } catch (e) {
      // Optionally handle error
    }
  }

  Future<void> _loadStudentData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _schoolController.text = data['school'] ?? '';
        _programController.text = data['program'] ?? '';
        _yearController.text = data['year']?.toString() ?? '';
        _semesterController.text = data['semester']?.toString() ?? '';
        // Load selected courses if present
        if (data['courses'] != null && data['courses'] is List) {
          _selectedCourseCodes = List<String>.from(data['courses']);
        }
      } else {
        _error = "Student profile not found.";
      }
    } catch (e) {
      _error = "Failed to load student data.";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .update({
        'name': _nameController.text.trim(),
        'school': _schoolController.text.trim(),
        'program': _programController.text.trim(),
        'year': int.tryParse(_yearController.text.trim()) ?? 1,
        'semester': int.tryParse(_semesterController.text.trim()) ?? 1,
        'courses': _selectedCourseCodes, // Save selected courses
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      setState(() {
        _error = "Failed to update profile.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _programController.dispose();
    _yearController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _schoolController,
                      decoration: const InputDecoration(
                        labelText: 'School',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your school';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _programController,
                      decoration: const InputDecoration(
                        labelText: 'Program',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your program';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your year';
                        }
                        final year = int.tryParse(value);
                        if (year == null || year < 1) {
                          return 'Please enter a valid year';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _semesterController,
                      decoration: const InputDecoration(
                        labelText: 'Semester',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timeline),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your semester';
                        }
                        final semester = int.tryParse(value);
                        if (semester == null || semester < 1) {
                          return 'Please enter a valid semester';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // --- Courses selection ---
                    Row(
                      children: [
                        const Icon(Icons.list_alt, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        Text(
                          'Select Courses',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._availableCourses.map((course) {
                      final code = course['courseCode'] ?? '';
                      final title = course['courseTitle'] ?? '';
                      return CheckboxListTile(
                        secondary: const Icon(Icons.check_box_outlined),
                        title: Text('$code - $title'),
                        value: _selectedCourseCodes.contains(code),
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedCourseCodes.add(code);
                            } else {
                              _selectedCourseCodes.remove(code);
                            }
                          });
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
