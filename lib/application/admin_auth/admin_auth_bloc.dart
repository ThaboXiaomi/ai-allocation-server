import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

import 'package:lecture_room_allocator/application/admin_auth/i_admin_auth_facade.dart';
import 'package:lecture_room_allocator/core/value_objects.dart';

part 'admin_auth_event.dart';
part 'admin_auth_state.dart';
part 'admin_auth_bloc.freezed.dart';

@injectable
class AdminAuthBloc extends Bloc<AdminAuthEvent, AdminAuthState> {
  final IAdminAuthFacade _adminAuthFacade;

  AdminAuthBloc(this._adminAuthFacade)
      : super(AdminAuthState.unauthenticated()) {
    on<EmailChanged>((event, emit) {
      emit(state.copyWith(
        emailAddress: EmailAddress(event.emailStr),
        authFailureOrSuccessOption: none(),
      ));
    });

    on<ResetPasswordPressed>((event, emit) async {
      if (!state.emailAddress.isValid()) {
        emit(state.copyWith(showErrorMessages: true));
        return;
      }

      emit(state.copyWith(
        isSubmitting: true,
        showErrorMessages: false,
        authFailureOrSuccessOption: none(),
      ));

      final failureOrSuccess = await _adminAuthFacade.sendPasswordResetEmail(
        emailAddress: state.emailAddress,
      );

      emit(state.copyWith(
        isSubmitting: false,
        showErrorMessages: true,
        authFailureOrSuccessOption: some(failureOrSuccess),
      ));
    });

    on<AuthCheckRequested>((event, emit) async {
      final userOption = await _adminAuthFacade.getSignedInAdmin();
      emit(userOption.fold(
        () => AdminAuthState.unauthenticated(),
        (_) => AdminAuthState.authenticated(),
      ));
    });

    on<SignedOut>((event, emit) async {
      await _adminAuthFacade.signOut();
      emit(AdminAuthState.unauthenticated());
    });
  }

  // Removed override of close() because IAdminAuthFacade has no dispose()
}
