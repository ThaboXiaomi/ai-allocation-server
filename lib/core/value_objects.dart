// value_objects.dart

class EmailAddress {
  final String value;

  EmailAddress(this.value);

  bool isValid() {
    // Simple email validation
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value);
  }
}