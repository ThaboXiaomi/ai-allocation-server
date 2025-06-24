part of 'admin_auth_bloc.dart';

@freezed
class AdminAuthState with _$AdminAuthState {
  const factory AdminAuthState({
    required EmailAddress emailAddress, // Kept as required, or you could provide a default
    @Default(false) bool isSubmitting,
    @Default(false) bool showErrorMessages,
    required Option<Either<AdminAuthFailure, Unit>> authFailureOrSuccessOption,
  }) = _AdminAuthState;

  factory AdminAuthState.initial() => AdminAuthState(
      emailAddress: EmailAddress(''),
      isSubmitting: false,
      showErrorMessages: false,
      authFailureOrSuccessOption: none(),
    );

  factory AdminAuthState.unauthenticated() {
    return AdminAuthState.initial();
  }

  factory AdminAuthState.authenticated() {
    return AdminAuthState.initial();
  }
}
