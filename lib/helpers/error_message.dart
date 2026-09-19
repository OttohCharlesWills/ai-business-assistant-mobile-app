import 'dart:async';
import 'dart:io';

/// Message shown when the phone can't reach the server.
const String kNoInternetMessage =
    'No internet connection. Please check your network and try again.';

/// True when [error] (an exception object or its text) is a connectivity
/// problem: no network, DNS failure, refused connection or a timeout.
bool isNetworkError(Object error) {
  if (error is SocketException || error is TimeoutException) return true;

  final text = error.toString();
  return text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('TimeoutException') ||
      text.contains('Failed host lookup') ||
      text.contains('Connection refused') ||
      text.contains('Connection reset') ||
      text.contains('Network is unreachable');
}

/// Use in place of `"Error: $e"`. Network problems become a plain message;
/// anything else keeps the old behaviour so real bugs stay visible.
String friendlyError(Object error) {
  if (isNetworkError(error)) return kNoInternetMessage;
  return 'Error: $error';
}