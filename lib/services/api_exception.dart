/// Thrown when the server answers but the answer is not usable
/// (expired session, server error, HTML instead of JSON, etc).
/// Its text is clean, so it is safe to show to the user.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}