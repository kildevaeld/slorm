class SlormException implements Exception {
  final String cause;
  SlormException(this.cause);
}

class FieldException extends SlormException {
  FieldException(String cause) : super(cause);
}
