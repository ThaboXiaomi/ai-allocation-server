import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
class AdminAuthEvent with _$AdminAuthEvent {
  const factory AdminAuthEvent.emailChanged(String emailStr) = EmailChanged;
  const factory AdminAuthEvent.resetPasswordPressed() = ResetPasswordPressed;
  const factory AdminAuthEvent.authCheckRequested() = AuthCheckRequested;
  const factory AdminAuthEvent.signedOut() = SignedOut;
}