import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './timetable_management_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableManagementPage extends StatefulWidget {
  @override
  State<TimetableManagementPage> createState() =>
      _TimetableManagementPageState();
}

class _TimetableManagementPageState extends State<TimetableManagementPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _school;
  String? _courseCode;
  String? _courseTitle;
  String? _lecturerId;
  String? _room;
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _editingDocId;
  String? _selectedCourseId;
  List<Map<String, dynamic>> _courses = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Add Timetable', icon: Icon(Icons.add)),
            Tab(text: 'View Timetables', icon: Icon(Icons.view_list)),
            Tab(text: 'Assign Students', icon: Icon(Icons.group_add)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: 'Add Course',
            onPressed: () => _showAddCourseDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Add Timetable Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  // School dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'School',
                      prefixIcon: Icon(Icons.school),
                    ),
                    value: _school,
                    items: const [
                      DropdownMenuItem(value: 'SET', child: Text('SET')),
                      DropdownMenuItem(value: 'SEM', child: Text('SEM')),
                      DropdownMenuItem(value: 'SOBE', child: Text('SOBE')),
                    ],
                    onChanged: (val) async {
                      setState(() {
                        _school = val;
                        _lecturerId = null;
                        _selectedCourseId = null;
                        _courseCode = null;
                        _courseTitle = null;
                      });
                      await _fetchCourses(val);
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => _school = v,
                  ),
                  // Course dropdown (filtered by school)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchCourses(_school),
                    builder: (context, snapshot) {
                      if (_school == null) return const SizedBox();
                      if (!snapshot.hasData)
                        return const CircularProgressIndicator();
                      final courses = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Course',
                          prefixIcon: Icon(Icons.book),
                        ),
                        value: _selectedCourseId,
                        items: courses
                            .map((course) => DropdownMenuItem<String>(
                                  value: course['id'],
                                  child: Text(
                                      '${course['courseCode']} - ${course['courseTitle']}'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCourseId = val;
                            final selectedCourse = courses.firstWhere(
                                (c) => c['id'] == val,
                                orElse: () => {});
                            _courseCode = selectedCourse['courseCode'] ?? '';
                            _courseTitle = selectedCourse['courseTitle'] ?? '';
                          });
                        },
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                        onSaved: (v) {
                          _selectedCourseId = v;
                          if (v != null) {
                            final selectedCourse = courses.firstWhere(
                                (c) => c['id'] == v,
                                orElse: () => {});
                            _courseCode = selectedCourse['courseCode'] ?? '';
                            _courseTitle = selectedCourse['courseTitle'] ?? '';
                          }
                        },
                      );
                    },
                  ),
                  // Lecturer dropdown
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchLecturers(_school),
                    builder: (context, snapshot) {
                      if (_school == null) {
                        return const SizedBox();
                      }
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final lecturers = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Lecturer',
                          prefixIcon: Icon(Icons.person),
                        ),
                        value: _lecturerId,
                        items: lecturers
                            .map<DropdownMenuItem<String>>(
                                (lecturer) => DropdownMenuItem<String>(
                                      value: lecturer['id'] as String,
                                      child: Text(lecturer['name'] as String),
                                    ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _lecturerId = val;
                          });
                        },
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                        onSaved: (v) => _lecturerId = v,
                      );
                    },
                  ),
                  // Room selection dropdown
                  FutureBuilder<List<String>>(
                    future: _fetchAvailableRooms(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final rooms = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Room',
                          prefixIcon: Icon(Icons.meeting_room),
                        ),
                        value: _room,
                        items: rooms
                            .map((room) => DropdownMenuItem(
                                  value: room,
                                  child: Text(room),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _room = val;
                          });
                        },
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                        onSaved: (v) => _room = v,
                      );
                    },
                  ),
                  ListTile(
                    title: Text(_date == null
                        ? 'Select Date'
                        : _date!.toLocal().toString().split(' ')[0]),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                  ),
                  ListTile(
                    title: Text(_startTime == null
                        ? 'Select Start Time'
                        : _startTime!.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => _startTime = picked);
                    },
                  ),
                  ListTile(
                    title: Text(_endTime == null
                        ? 'Select End Time'
                        : _endTime!.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => _endTime = picked);
                    },
                  ),
                  const SizedBox(height: 20),
                  BlocConsumer<TimetableManagementBloc, TimetableState>(
                    listener: (context, state) {
                      if (state is TimetableSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Timetable added!')),
                        );
                      } else if (state is TimetableFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${state.error}')),
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is TimetableLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            _formKey.currentState?.save();
                            if (_date == null ||
                                _startTime == null ||
                                _endTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please select date and time')),
                              );
                              return;
                            }
                            if ((_courseCode == null || _courseCode!.isEmpty) ||
                                (_courseTitle == null || _courseTitle!.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please select a valid course.')),
                              );
                              return;
                            }
                            final timetableData = {
                              'school': _school,
                              'courseCode': _courseCode,
                              'courseTitle': _courseTitle,
                              'lecturerId': _lecturerId,
                              'room': _room,
                              'date': _date!.toIso8601String(),
                              'startTime': _startTime!.format(context),
                              'endTime': _endTime!.format(context),
                              'students': [],
                            };
                            if (_editingDocId != null) {
                              // Update existing
                              await FirebaseFirestore.instance
                                  .collection('timetables')
                                  .doc(_editingDocId)
                                  .update(timetableData);
                              setState(() {
                                _editingDocId = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Timetable updated!')),
                              );
                            } else {
                              // Add new
                              context
                                  .read<TimetableManagementBloc>()
                                  .add(AddTimetable(timetableData));
                            }
                            _formKey.currentState?.reset();
                            setState(() {
                              _date = null;
                              _startTime = null;
                              _endTime = null;
                              _courseCode = null;
                              _courseTitle = null;
                              _selectedCourseId = null;
                            });
                          }
                        },
                        child: Text(_editingDocId != null
                            ? 'Update Timetable'
                            : 'Add Timetable'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // View Timetables Tab
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('timetables')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No timetables found.'));
                }
                final timetables = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: timetables.length,
                  itemBuilder: (context, index) {
                    final doc = timetables[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text(
                            '${data['courseCode'] ?? ''} - ${data['courseTitle'] ?? ''}'),
                        subtitle: Text(
                          'School: ${data['school'] ?? ''}\n'
                          'Lecturer: ${data['lecturerId'] ?? ''}\n'
                          'Room: ${data['room'] ?? ''}\n'
                          'Date: ${data['date']?.toString().split("T")[0] ?? ''}\n'
                          'Start: ${data['startTime'] ?? ''} - End: ${data['endTime'] ?? ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                setState(() {
                                  _school = data['school'];
                                  _courseCode = data['courseCode'];
                                  _courseTitle = data['courseTitle'];
                                  _lecturerId = data['lecturerId'];
                                  _room = data['room'];
                                  _date = DateTime.tryParse(data['date'] ?? '');
                                  _startTime =
                                      _parseTimeOfDay(data['startTime']);
                                  _endTime = _parseTimeOfDay(data['endTime']);
                                  _editingDocId = doc.id;
                                  _selectedCourseId = null;
                                });
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Edit Timetable'),
                                    content: const Text(
                                        'Edit the fields above and press "Update Timetable".'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                                _tabController.animateTo(0);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('timetables')
                                    .doc(doc.id)
                                    .delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Timetable deleted')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Assign Students Tab
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('timetables')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No timetables found.'));
                }
                final timetables = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: timetables.length,
                  itemBuilder: (context, index) {
                    final doc = timetables[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final school = data['school'] ?? '';
                    final courseTitle = data['courseTitle'] ?? '';
                    return Card(
                      child: ListTile(
                        title: Text(
                            '${data['courseCode'] ?? ''} - ${data['courseTitle'] ?? ''}'),
                        subtitle: Text(
                          'School: $school\n'
                          'Lecturer: ${data['lecturerId'] ?? ''}\n'
                          'Room: ${data['room'] ?? ''}\n'
                          'Date: ${data['date']?.toString().split("T")[0] ?? ''}\n'
                          'Start: ${data['startTime'] ?? ''} - End: ${data['endTime'] ?? ''}',
                        ),
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.group_add),
                          label: const Text('Assign Students'),
                          onPressed: () async {
                            final timetableDocId = doc.id;

                            if (courseTitle.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Course title not specified for this timetable.')),
                              );
                              return;
                            }

                            await assignStudents(
                              school: school,
                              courseTitle: courseTitle,
                              timetableDocId: timetableDocId,
                              context: context,
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TimeOfDay? _parseTimeOfDay(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<List<String>> _fetchAvailableRooms() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('lecture_rooms')
        .where('status', isEqualTo: 'Available')
        .get();
    return snapshot.docs.map((doc) => doc['name'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchLecturers(String? school) async {
    if (school == null) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('lecturers')
        .where('school', isEqualTo: school)
        .get();
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'] ?? doc.id,
            })
        .toList();
  }

  // --- Add Course Dialog ---
  Future<void> _showAddCourseDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    String? _dialogSchool;
    String? _dialogCourseCode;
    String? _dialogCourseTitle;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Course'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'School'),
                items: const [
                  DropdownMenuItem(value: 'SET', child: Text('SET')),
                  DropdownMenuItem(value: 'SEM', child: Text('SEM')),
                  DropdownMenuItem(value: 'SOBE', child: Text('SOBE')),
                ],
                onChanged: (val) => _dialogSchool = val,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Course Code'),
                onChanged: (v) => _dialogCourseCode = v,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Course Title'),
                onChanged: (v) => _dialogCourseTitle = v,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await FirebaseFirestore.instance.collection('courses').add({
                  'school': _dialogSchool,
                  'courseCode': _dialogCourseCode,
                  'courseTitle': _dialogCourseTitle,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Course added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // --- Fetch courses for a school ---
  Future<List<Map<String, dynamic>>> _fetchCourses(String? school) async {
    if (school == null) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('school', isEqualTo: school)
        .get();
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'courseCode': doc['courseCode'],
              'courseTitle': doc['courseTitle'],
            })
        .toList();
  }

  // --- Assign students to timetable ---
  Future<void> assignStudents({
    required String school,
    required String courseTitle,
    required String timetableDocId,
    required BuildContext context,
  }) async {
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('school', isEqualTo: school)
        .where('courses', arrayContains: courseTitle)
        .get();

    final students = studentsSnapshot.docs;

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No students registered for this course.')),
      );
      return;
    }

    List<String> selectedStudentIds = students.map((d) => d.id).toList();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Students'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: students.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final studentId = doc.id;
                return CheckboxListTile(
                  value: selectedStudentIds.contains(studentId),
                  title: Text('${data['name']} (${data['matricNo']})'),
                  subtitle: Text(data['email'] ?? ''),
                  onChanged: (checked) {
                    if (checked == true) {
                      if (!selectedStudentIds.contains(studentId)) {
                        selectedStudentIds.add(studentId);
                      }
                    } else {
                      selectedStudentIds.remove(studentId);
                    }
                    (context as Element).markNeedsBuild();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('timetables')
                    .doc(timetableDocId)
                    .update({'students': selectedStudentIds});
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Successfully assigned ${selectedStudentIds.length} students.'),
                  ),
                );
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }
}
