part of 'admin_auth_bloc.dart';

@freezed
class AdminAuthEvent with _$AdminAuthEvent {
  const factory AdminAuthEvent.emailChanged(String emailStr) = EmailChanged;
  const factory AdminAuthEvent.resetPasswordPressed() = ResetPasswordPressed;
  const factory AdminAuthEvent.authCheckRequested() = AuthCheckRequested;
  const factory AdminAuthEvent.signedOut() = SignedOut;
}
