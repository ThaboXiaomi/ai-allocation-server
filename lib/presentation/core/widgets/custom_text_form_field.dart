import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  const CustomTextFormField({
    Key? key,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
