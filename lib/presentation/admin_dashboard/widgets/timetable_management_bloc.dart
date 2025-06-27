import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Timetable Event
abstract class TimetableEvent extends Equatable {
  const TimetableEvent();
}

class AddTimetable extends TimetableEvent {
  final Map<String, dynamic>
      timetableData; // Should include: courseId, lecturerId, faculty, room, time, etc.

  const AddTimetable(this.timetableData);

  @override
  List<Object?> get props => [timetableData];
}

// New event to fetch lecturers by faculty
class FetchLecturersByFaculty extends TimetableEvent {
  final String faculty; // SET, SOBE, SEM

  const FetchLecturersByFaculty(this.faculty);

  @override
  List<Object?> get props => [faculty];
}

// Timetable State
abstract class TimetableState extends Equatable {
  const TimetableState();
}

class TimetableInitial extends TimetableState {
  @override
  List<Object?> get props => [];
}

class TimetableLoading extends TimetableState {
  @override
  List<Object?> get props => [];
}

class TimetableSuccess extends TimetableState {
  @override
  List<Object?> get props => [];
}

class TimetableFailure extends TimetableState {
  final String error;

  const TimetableFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// New state for loaded lecturers
class LecturersLoaded extends TimetableState {
  final List<Map<String, dynamic>>
      lecturers; // Each lecturer: {id, name, faculty, ...}

  const LecturersLoaded(this.lecturers);

  @override
  List<Object?> get props => [lecturers];
}

// Bloc Implementation
class TimetableManagementBloc extends Bloc<TimetableEvent, TimetableState> {
  final FirebaseFirestore firestore;

  TimetableManagementBloc({required this.firestore})
      : super(TimetableInitial()) {
    on<AddTimetable>(_onAddTimetable);
    on<FetchLecturersByFaculty>(_onFetchLecturersByFaculty);
  }

  Future<void> _onAddTimetable(
      AddTimetable event, Emitter<TimetableState> emit) async {
    emit(TimetableLoading());
    try {
      // Save timetable to Firestore under 'timetables' collection
      await firestore.collection('timetables').add(event.timetableData);
      emit(TimetableSuccess());
    } catch (e) {
      emit(TimetableFailure(e.toString()));
    }
  }

  Future<void> _onFetchLecturersByFaculty(
      FetchLecturersByFaculty event, Emitter<TimetableState> emit) async {
    emit(TimetableLoading());
    try {
      // Fetch lecturers where faculty matches (e.g., 'SET', 'SOBE', 'SEM')
      final querySnapshot = await firestore
          .collection('lecturers')
          .where('faculty', isEqualTo: event.faculty)
          .get();

      final lecturers = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      emit(LecturersLoaded(lecturers));
    } catch (e) {
      emit(TimetableFailure(e.toString()));
    }
  }
}

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({Key? key}) : super(key: key);

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    // Avoid showing SnackBars in dispose, but you can use _scaffoldMessenger if needed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Timetable Management'),
      ),
      body: BlocConsumer<TimetableManagementBloc, TimetableState>(
        listener: (context, state) {
          if (state is TimetableFailure) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.error}')),
            );
          } else if (state is TimetableSuccess) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Timetable added successfully')),
            );
          }
        },
        builder: (context, state) {
          if (state is TimetableLoading) {
            return Center(child: CircularProgressIndicator());
          }
          return Center(
            child: Text('Timetable Screen'),
          );
        },
      ),
    );
  }
}
