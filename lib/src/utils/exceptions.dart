/// Exception thrown when a Marionette operation fails.
///
/// Contains an error code that can be used for structured error output.
class MarionetteException implements Exception {
  const MarionetteException(
    this.message, {
    this.code = 'MARIONETTE_ERROR',
  });

  final String message;
  final String code;

  /// Creates an exception from a marionette_flutter error message.
  ///
  /// Parses the error message to determine the appropriate error code.
  factory MarionetteException.fromError(String errorMessage) {
    final lowerMessage = errorMessage.toLowerCase();

    String code;
    if (lowerMessage.contains('not found')) {
      code = 'ELEMENT_NOT_FOUND';
    } else if (lowerMessage.contains('timeout')) {
      code = 'TIMEOUT';
    } else if (lowerMessage.contains('not connected')) {
      code = 'NOT_CONNECTED';
    } else if (lowerMessage.contains('no scrollable')) {
      code = 'NOT_SCROLLABLE';
    } else if (lowerMessage.contains('not a text field') ||
        lowerMessage.contains('cannot enter text')) {
      code = 'INVALID_ELEMENT';
    } else {
      code = 'MARIONETTE_ERROR';
    }

    // Clean up the error message
    String cleanMessage = errorMessage;
    if (cleanMessage.startsWith('Exception: ')) {
      cleanMessage = cleanMessage.substring('Exception: '.length);
    }

    return MarionetteException(cleanMessage, code: code);
  }

  @override
  String toString() => 'MarionetteException: $message';
}
