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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, "/admin-dashboard");
          },
        ),
        title: const Text(
          'Timetable Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        backgroundColor: Theme.of(context).primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              text: 'Add Timetable',
              icon: Icon(Icons.add_circle_outline),
            ),
            Tab(
              text: 'View Timetables',
              icon: Icon(Icons.calendar_today),
            ),
            Tab(
              text: 'Assign Students',
              icon: Icon(Icons.group_add),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded, color: Colors.white),
            tooltip: 'Add New Course',
            onPressed: () => _showAddCourseDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[100]!, Colors.grey[200]!],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // Add Timetable Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        // School dropdown
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'School',
                            prefixIcon:
                                Icon(Icons.school, color: Colors.blueGrey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
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
                        const SizedBox(height: 16),
                        // Course dropdown
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _fetchCourses(_school),
                          builder: (context, snapshot) {
                            if (_school == null) return const SizedBox();
                            if (!snapshot.hasData)
                              return const Center(
                                  child: CircularProgressIndicator());
                            final courses = snapshot.data!;
                            return DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Course',
                                prefixIcon:
                                    Icon(Icons.book, color: Colors.blueGrey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              value: _selectedCourseId,
                              items: courses
                                  .map((course) => DropdownMenuItem<String>(
                                        value: course['id'],
                                        child: Text(
                                          '${course['courseCode']} - ${course['courseTitle']}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedCourseId = val;
                                  final selectedCourse = courses.firstWhere(
                                      (c) => c['id'] == val,
                                      orElse: () => {});
                                  _courseCode =
                                      selectedCourse['courseCode'] ?? '';
                                  _courseTitle =
                                      selectedCourse['courseTitle'] ?? '';
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
                                  _courseCode =
                                      selectedCourse['courseCode'] ?? '';
                                  _courseTitle =
                                      selectedCourse['courseTitle'] ?? '';
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Lecturer dropdown
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _fetchLecturers(_school),
                          builder: (context, snapshot) {
                            if (_school == null) return const SizedBox();
                            if (!snapshot.hasData)
                              return const Center(
                                  child: CircularProgressIndicator());
                            final lecturers = snapshot.data!;
                            return DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Lecturer',
                                prefixIcon:
                                    Icon(Icons.person, color: Colors.blueGrey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              value: _lecturerId,
                              items: lecturers
                                  .map<DropdownMenuItem<String>>(
                                      (lecturer) => DropdownMenuItem<String>(
                                            value: lecturer['id'] as String,
                                            child: Text(
                                              lecturer['name'] as String,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500),
                                            ),
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
                        const SizedBox(height: 16),
                        // Room dropdown
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _fetchAvailableRooms(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const Center(
                                  child: CircularProgressIndicator());
                            final rooms = snapshot.data!;
                            return DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Room',
                                prefixIcon: Icon(Icons.meeting_room,
                                    color: Colors.blueGrey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              value: _room,
                              items: rooms
                                  .map((room) => DropdownMenuItem(
                                        value: room['id'] as String,
                                        child: Text(
                                          room['name'],
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500),
                                        ),
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
                        const SizedBox(height: 16),
                        // Date picker
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tileColor: Colors.white,
                          title: Text(
                            _date == null
                                ? 'Select Date'
                                : _date!.toLocal().toString().split(' ')[0],
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing:
                              const Icon(Icons.calendar_today, color: Colors.blueGrey),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Theme.of(context).primaryColor,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) setState(() => _date = picked);
                          },
                        ),
                        const SizedBox(height: 16),
                        // Start time picker
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tileColor: Colors.white,
                          title: Text(
                            _startTime == null
                                ? 'Select Start Time'
                                : _startTime!.format(context),
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing:
                              const Icon(Icons.access_time, color: Colors.blueGrey),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Theme.of(context).primaryColor,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null)
                              setState(() => _startTime = picked);
                          },
                        ),
                        const SizedBox(height: 16),
                        // End time picker
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          tileColor: Colors.white,
                          title: Text(
                            _endTime == null
                                ? 'Select End Time'
                                : _endTime!.format(context),
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing:
                              const Icon(Icons.access_time, color: Colors.blueGrey),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Theme.of(context).primaryColor,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null)
                              setState(() => _endTime = picked);
                          },
                        ),
                        const SizedBox(height: 24),
                        BlocConsumer<TimetableManagementBloc, TimetableState>(
                          listener: (context, state) {
                            if (state is TimetableSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      _editingDocId != null
                                          ? 'Timetable updated successfully!'
                                          : 'Timetable added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else if (state is TimetableFailure) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${state.error}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          builder: (context, state) {
                            if (state is TimetableLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            return ElevatedButton.icon(
                              icon: Icon(_editingDocId != null
                                  ? Icons.update
                                  : Icons.add),
                              label: Text(_editingDocId != null
                                  ? 'Update Timetable'
                                  : 'Add Timetable'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                if (_formKey.currentState?.validate() ?? false) {
                                  _formKey.currentState?.save();
                                  if (_date == null ||
                                      _startTime == null ||
                                      _endTime == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Please select date and time'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  if ((_courseCode == null ||
                                          _courseCode!.isEmpty) ||
                                      (_courseTitle == null ||
                                          _courseTitle!.isEmpty)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Please select a valid course.'),
                                        backgroundColor: Colors.red,
                                      ),
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
                                    // Update existing timetable
                                    await FirebaseFirestore.instance
                                        .collection('timetables')
                                        .doc(_editingDocId)
                                        .update(timetableData);
                                    setState(() {
                                      _editingDocId = null;
                                    });
                                  } else {
                                    // Add new timetable
                                    final docRef = await FirebaseFirestore
                                        .instance
                                        .collection('timetables')
                                        .add(timetableData);
                                    final allocationId = docRef.id;
                                    await docRef
                                        .update({'allocationId': allocationId});

                                    // Fetch room name for notification
                                    String roomName = '';
                                    if (_room != null && _room!.isNotEmpty) {
                                      final roomDoc = await FirebaseFirestore
                                          .instance
                                          .collection('lecture_rooms')
                                          .doc(_room)
                                          .get();
                                      roomName = roomDoc.exists
                                          ? (roomDoc['name'] ?? 'Room')
                                          : 'Room';
                                    }

                                    // Send notification to lecturer
                                    await FirebaseFirestore.instance
                                        .collection('notifications')
                                        .add({
                                      'type': 'timetable_created',
                                      'title': 'New Timetable Assigned',
                                      'message':
                                          'You have been assigned a new lecture: ${_courseCode ?? ''} - ${_courseTitle ?? ''} in $roomName on ${_date != null ? _date!.toLocal().toString().split(' ')[0] : ''} at ${_startTime != null ? _startTime!.format(context) : ''}.',
                                      'lecturerId': _lecturerId ?? '',
                                      'timetableId': allocationId,
                                      'isRead': false,
                                      'time': DateTime.now().toIso8601String(),
                                    });
                                  }
                                  _formKey.currentState?.reset();
                                  setState(() {
                                    _date = null;
                                    _startTime = null;
                                    _endTime = null;
                                    _courseCode = null;
                                    _courseTitle = null;
                                    _selectedCourseId = null;
                                    _school = null;
                                    _lecturerId = null;
                                    _room = null;
                                  });
                                }
                              },
                            );
                          },
                        ),
                        if (_editingDocId != null) ...[
                          const SizedBox(height: 16),
                          TextButton.icon(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            label: const Text('Cancel Editing'),
                            onPressed: () {
                              setState(() {
                                _editingDocId = null;
                                _formKey.currentState?.reset();
                                _date = null;
                                _startTime = null;
                                _endTime = null;
                                _courseCode = null;
                                _courseTitle = null;
                                _selectedCourseId = null;
                                _school = null;
                                _lecturerId = null;
                                _room = null;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
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
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No timetables found.',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    );
                  }
                  final timetables = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: timetables.length,
                    itemBuilder: (context, index) {
                      final doc = timetables[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.event,
                                color: Colors.white, size: 24),
                          ),
                          title: Text(
                            '${data['courseCode'] ?? ''} - ${data['courseTitle'] ?? ''}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('lecture_rooms')
                                .doc(data['room'])
                                .get(),
                            builder: (context, roomSnapshot) {
                              String roomName = 'Unknown';
                              if (roomSnapshot.hasData &&
                                  roomSnapshot.data!.exists) {
                                roomName = roomSnapshot.data!['name'] ?? 'Room';
                              }
                              return Text(
                                'School: ${data['school'] ?? ''}\n'
                                'Lecturer: ${data['lecturerId'] ?? ''}\n'
                                'Room: $roomName\n'
                                'Date: ${data['date']?.toString().split("T")[0] ?? ''}\n'
                                'Time: ${data['startTime'] ?? ''} - ${data['endTime'] ?? ''}',
                                style: const TextStyle(fontSize: 14),
                              );
                            },
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue, size: 24),
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
                                  _tabController.animateTo(0);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Edit the form and press Update Timetable'),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 24),
                                onPressed: () async {
                                  bool? confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: const Text(
                                          'Are you sure you want to delete this timetable?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance
                                        .collection('timetables')
                                        .doc(doc.id)
                                        .delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Timetable deleted'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
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
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No timetables found.',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    );
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
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.group,
                                color: Colors.white, size: 24),
                          ),
                          title: Text(
                            '${data['courseCode'] ?? ''} - ${data['courseTitle'] ?? ''}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            'School: $school\n'
                            'Lecturer: ${data['lecturerId'] ?? ''}\n'
                            'Room: ${data['room'] ?? ''}\n'
                            'Date: ${data['date']?.toString().split("T")[0] ?? ''}\n'
                            'Time: ${data['startTime'] ?? ''} - ${data['endTime'] ?? ''}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: ElevatedButton.icon(
                            icon: const Icon(Icons.group_add),
                            label: const Text('Assign'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              final timetableDocId = doc.id;
                              if (courseTitle.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Course title not specified for this timetable.'),
                                    backgroundColor: Colors.red,
                                  ),
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
      ),
    );
  }

  TimeOfDay? _parseTimeOfDay(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1].split(' ')[0]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<List<Map<String, dynamic>>> _fetchAvailableRooms() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('lecture_rooms')
        .where('status', isEqualTo: 'Available')
        .get();
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'] as String,
            })
        .toList();
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

  Future<void> _showAddCourseDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    String? _dialogSchool;
    String? _dialogCourseCode;
    String? _dialogCourseTitle;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Add New Course'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'School',
                    prefixIcon: Icon(Icons.school, color: Colors.blueGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'SET', child: Text('SET')),
                    DropdownMenuItem(value: 'SEM', child: Text('SEM')),
                    DropdownMenuItem(value: 'SOBE', child: Text('SOBE')),
                  ],
                  onChanged: (val) => _dialogSchool = val,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Course Code',
                    prefixIcon: Icon(Icons.code, color: Colors.blueGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) => _dialogCourseCode = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Course Title',
                    prefixIcon: Icon(Icons.title, color: Colors.blueGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) => _dialogCourseTitle = v,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Course'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                await FirebaseFirestore.instance.collection('courses').add({
                  'school': _dialogSchool,
                  'courseCode': _dialogCourseCode,
                  'courseTitle': _dialogCourseTitle,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Course added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                if (_school == _dialogSchool) {
                  await _fetchCourses(_school);
                  setState(() {});
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchCourses(String? school) async {
    if (school == null) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('school', isEqualTo: school)
        .get();
    setState(() {
      _courses = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'courseCode': doc['courseCode'],
                'courseTitle': doc['courseTitle'],
              })
          .toList();
    });
    return _courses;
  }

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
        const SnackBar(
          content: Text('No students registered for this course.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<String> selectedStudentIds = students.map((d) => d.id).toList();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Assign Students'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: students.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final studentId = doc.id;
                return Card(
                  child: CheckboxListTile(
                    value: selectedStudentIds.contains(studentId),
                    title: Text(
                      '${data['name']} (${data['matricNo']})',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(data['email'] ?? ''),
                    secondary: const Icon(Icons.person, color: Colors.blueGrey),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          if (!selectedStudentIds.contains(studentId)) {
                            selectedStudentIds.add(studentId);
                          }
                        } else {
                          selectedStudentIds.remove(studentId);
                        }
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Assign'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}