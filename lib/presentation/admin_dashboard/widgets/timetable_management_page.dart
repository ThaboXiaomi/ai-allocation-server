import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './timetable_management_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableManagementPage extends StatefulWidget {
  @override
  State<TimetableManagementPage> createState() => _TimetableManagementPageState();
}

class _TimetableManagementPageState extends State<TimetableManagementPage> {
  final _formKey = GlobalKey<FormState>();
  String? _school;
  String? _courseCode;
  String? _courseTitle;
  String? _lecturerId;
  String? _room;
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timetable Management')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'School'),
                onSaved: (v) => _school = v,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Course Code'),
                onSaved: (v) => _courseCode = v,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Course Title'),
                onSaved: (v) => _courseTitle = v,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Lecturer ID'),
                onSaved: (v) => _lecturerId = v,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Room'),
                onSaved: (v) => _room = v,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              ListTile(
                title: Text(_date == null ? 'Select Date' : _date!.toLocal().toString().split(' ')[0]),
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
                title: Text(_startTime == null ? 'Select Start Time' : _startTime!.format(context)),
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
                title: Text(_endTime == null ? 'Select End Time' : _endTime!.format(context)),
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
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();
                        if (_date == null || _startTime == null || _endTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select date and time')),
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
                          'students': [], // Optionally add student IDs here
                        };
                        context.read<TimetableManagementBloc>().add(AddTimetable(timetableData));
                      }
                    },
                    child: const Text('Add Timetable'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}