import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lecture_room_allocator/application/admin_auth/admin_auth_bloc.dart';
import 'package:lecture_room_allocator/application/admin_auth/admin_auth_failure.dart';

import 'package:lecture_room_allocator/presentation/core/widgets/custom_text_form_field.dart';
import 'package:lecture_room_allocator/presentation/core/widgets/primary_button.dart';

class AdminPasswordResetPage extends StatelessWidget {
  const AdminPasswordResetPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Password Reset')),
      body: BlocConsumer<AdminAuthBloc, AdminAuthState>(
        listener: (context, state) {
          state.authFailureOrSuccessOption.fold(
            () {},
            (either) => either.fold(
              (failure) {
                String message;
                if (failure is ServerError) {
                  message = 'Server error';
                } else if (failure is InvalidEmail) {
                  message = 'Invalid email';
                } else if (failure is UserNotFound) {
                  message = 'User not found';
                } else {
                  message = 'Unexpected error';
                }
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(message)));
              },
              (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password reset email sent successfully'),
                  ),
                );
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
          );
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              autovalidateMode: state.showErrorMessages
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              child: ListView(
                children: [
                  const SizedBox(height: 8),
                  CustomTextFormField(
                    hintText: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => context
                        .read<AdminAuthBloc>()
                        .add(AdminAuthEvent.emailChanged(value)),
                    validator: (_) =>
                        state.emailAddress.isValid() ? null : 'Invalid email',
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: state.isSubmitting ? 'Sending...' : 'Reset Password',
                    onPressed: state.isSubmitting
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            context.read<AdminAuthBloc>().add(
                                const AdminAuthEvent.resetPasswordPressed());
                          },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('Back to login'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
