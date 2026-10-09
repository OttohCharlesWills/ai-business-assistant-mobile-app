
import 'dart:async';
import 'dart:io';

/// Message shown when the phone cannot reach the server.
const String kNoInternetMessage =
    'No internet connection. Please check your network and try again.';

/// Exception used when a network failure is detected.
class FriendlyNetworkException implements Exception {
  const FriendlyNetworkException();

  @override
  String toString() => kNoInternetMessage;
}

/// Returns true when [error] represents a network or connection problem.
bool isNetworkError(Object error) {
  if (error is FriendlyNetworkException ||
      error is SocketException ||
      error is TimeoutException) {
    return true;
  }

  final text = error.toString().toLowerCase();

  return text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('timeoutexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection refused') ||
      text.contains('connection reset') ||
      text.contains('network is unreachable') ||
      text.contains('no address associated with hostname') ||
      text.contains('connection timed out') ||
      text.contains('failed to fetch') ||
      text.contains('network_error') ||
      text.contains('no internet connection') ||
      text.contains('software caused connection abort') ||
      text.contains('broken pipe') ||
      text.contains('handshakeexception');
}

/// Converts errors into messages suitable for displaying to users.
///
/// Network errors display a consistent connection message.
/// Other errors display a general message instead of exposing
/// technical details.
String friendlyError(Object error) {
  if (isNetworkError(error)) {
    return kNoInternetMessage;
  }

  return 'Something went wrong. Please try again.';
}
