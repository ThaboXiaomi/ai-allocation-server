// admin_auth_failure.dart

import 'package:freezed_annotation/freezed_annotation.dart'; // Make sure you import this

part 'admin_auth_failure.freezed.dart'; // <--- Make sure this line exists and matches your file name

@freezed // <--- Make sure this annotation is here
abstract class AdminAuthFailure with _$AdminAuthFailure {
  const factory AdminAuthFailure.serverError() = ServerError;
  const factory AdminAuthFailure.invalidEmail() = InvalidEmail;
  const factory AdminAuthFailure.userNotFound() = UserNotFound;
  const factory AdminAuthFailure.unexpected() = Unexpected;
  // Add other failure cases as needed
}
