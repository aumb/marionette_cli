import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Manages session state for the Marionette CLI.
///
/// Stores the active VM service connection in a session file within
/// the current project directory, allowing subsequent commands to
/// auto-reconnect without requiring the URI to be specified each time.
class Session {
  static const String _sessionFileName = '.marionette_session';

  /// Gets the session file path (in current working directory).
  static String get _sessionFilePath {
    return path.join(Directory.current.path, _sessionFileName);
  }

  /// Saves the current session with the given VM service URI.
  static Future<void> save({
    required String vmServiceUri,
    String? isolateId,
  }) async {
    final sessionData = {
      'vmServiceUri': vmServiceUri,
      if (isolateId != null) 'isolateId': isolateId,
      'connectedAt': DateTime.now().toIso8601String(),
    };

    final file = File(_sessionFilePath);
    await file.writeAsString(jsonEncode(sessionData));
  }

  /// Loads the current session if one exists.
  ///
  /// Returns null if no session exists or if it's invalid.
  static Future<SessionData?> load() async {
    final file = File(_sessionFilePath);

    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return SessionData.fromJson(data);
    } catch (e) {
      // Invalid session file, delete it
      await clear();
      return null;
    }
  }

  /// Clears the current session.
  static Future<void> clear() async {
    final file = File(_sessionFilePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Checks if a session exists.
  static Future<bool> exists() async {
    final file = File(_sessionFilePath);
    return file.exists();
  }
}

/// Data class representing a saved session.
class SessionData {
  /// The VM service URI for the connected Flutter app.
  final String vmServiceUri;

  /// The isolate ID if available.
  final String? isolateId;

  /// When the session was created.
  final DateTime connectedAt;

  const SessionData({
    required this.vmServiceUri,
    this.isolateId,
    required this.connectedAt,
  });

  /// Creates a SessionData from a JSON map.
  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      vmServiceUri: json['vmServiceUri'] as String,
      isolateId: json['isolateId'] as String?,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
    );
  }

  /// Converts this session to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'vmServiceUri': vmServiceUri,
      if (isolateId != null) 'isolateId': isolateId,
      'connectedAt': connectedAt.toIso8601String(),
    };
  }
}
