import 'package:dartz/dartz.dart';
import 'package:lecture_room_allocator/core/value_objects.dart';

// Define the AdminAuthFailure class if it does not already exist
class AdminAuthFailure {
  final String message;
  AdminAuthFailure(this.message);
}

abstract class IAdminAuthFacade {
  Future<Either<AdminAuthFailure, Unit>> sendPasswordResetEmail({
    required EmailAddress emailAddress,
  });

  Future<Option<Unit>> getSignedInAdmin();

  Future<void> signOut();
}