import 'dart:convert';
import 'dart:io';

/// Utility for consistent JSON output formatting.
///
/// All CLI commands should use this for their output to ensure
/// AI models can reliably parse the responses.
class Output {
  /// Whether to format JSON with indentation for human readability.
  static bool prettyPrint = false;

  /// Prints a success response with the given data.
  static void success(Map<String, dynamic> data, {String? message}) {
    final response = <String, dynamic>{
      'success': true,
      if (message != null) 'message': message,
      ...data,
    };
    _print(response);
  }

  /// Prints an error response.
  static void error(
    String message, {
    String? code,
    Map<String, dynamic>? details,
  }) {
    final response = <String, dynamic>{
      'success': false,
      'error': {
        if (code != null) 'code': code,
        'message': message,
        if (details != null) ...details,
      },
    };
    _print(response);
  }

  /// Prints a raw JSON response.
  static void json(Map<String, dynamic> data) {
    _print(data);
  }

  /// Prints a list response.
  static void list(String key, List<dynamic> items, {String? message}) {
    final response = <String, dynamic>{
      'success': true,
      if (message != null) 'message': message,
      key: items,
      'count': items.length,
    };
    _print(response);
  }

  static void _print(Map<String, dynamic> data) {
    final encoder =
        prettyPrint ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    stdout.writeln(encoder.convert(data));
  }
}

/// Exit codes for the CLI.
///
/// These follow Unix conventions and provide meaningful codes
/// for different error scenarios.
class ExitCode {
  /// Command completed successfully.
  static const int success = 0;

  /// General error.
  static const int error = 1;

  /// Invalid usage or arguments.
  static const int usage = 64;

  /// Connection error (e.g., cannot connect to VM service).
  static const int connection = 69;

  /// Service unavailable (e.g., app not running).
  static const int unavailable = 69;

  /// Element not found.
  static const int notFound = 70;

  /// Operation timed out.
  static const int timeout = 75;

  /// Configuration error.
  static const int config = 78;
}
