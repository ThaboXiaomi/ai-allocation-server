import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

// Timetable Event
abstract class TimetableEvent extends Equatable {
  const TimetableEvent();
}

class AddTimetable extends TimetableEvent {
  final Map<String, dynamic> timetableData; // e.g. {courseId, lecturerId, room, time, etc.}

  const AddTimetable(this.timetableData);

  @override
  List<Object?> get props => [timetableData];
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

// Bloc Implementation
class TimetableManagementBloc extends Bloc<TimetableEvent, TimetableState> {
  final FirebaseFirestore firestore;

  TimetableManagementBloc({required this.firestore}) : super(TimetableInitial()) {
    on<AddTimetable>(_onAddTimetable);
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
}