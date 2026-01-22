import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../models/interactive_element.dart';
import '../utils/exceptions.dart';
import '../utils/session.dart';

/// Client for communicating with a Flutter app's VM Service.
///
/// This client manages the WebSocket connection and provides methods
/// for invoking Marionette extensions on the connected Flutter app.
class VmServiceClient {
  VmService? _service;
  String? _isolateId;
  String? _vmServiceUri;

  /// Whether we're currently connected to a VM service.
  bool get isConnected => _service != null && _isolateId != null;

  /// The current VM service URI if connected.
  String? get vmServiceUri => _vmServiceUri;

  /// The current isolate ID if connected.
  String? get isolateId => _isolateId;

  /// Connects to a Flutter app via its VM service URI.
  ///
  /// The [uri] should be in the format `ws://127.0.0.1:XXXXX/ws`.
  /// Optionally saves the session for subsequent commands.
  Future<Map<String, dynamic>> connect(
    String uri, {
    bool saveSession = true,
  }) async {
    // Normalize the URI
    var normalizedUri = uri;
    if (!normalizedUri.startsWith('ws://') &&
        !normalizedUri.startsWith('wss://')) {
      // Try to convert http to ws
      normalizedUri = normalizedUri
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');
    }
    if (!normalizedUri.endsWith('/ws')) {
      normalizedUri = normalizedUri.endsWith('/')
          ? '${normalizedUri}ws'
          : '$normalizedUri/ws';
    }

    try {
      _service = await vmServiceConnectUri(normalizedUri);
      _vmServiceUri = normalizedUri;

      // Get the main isolate
      final vm = await _service!.getVM();
      final isolates = vm.isolates ?? [];

      if (isolates.isEmpty) {
        throw StateError('No isolates found in the VM');
      }

      // Find the main UI isolate
      IsolateRef? mainIsolate;
      for (final isolate in isolates) {
        if (isolate.name?.contains('main') == true ||
            isolate.name?.contains('root') == true) {
          mainIsolate = isolate;
          break;
        }
      }
      mainIsolate ??= isolates.first;
      _isolateId = mainIsolate.id;

      // Save the session
      if (saveSession) {
        await Session.save(
          vmServiceUri: normalizedUri,
          isolateId: _isolateId,
        );
      }

      return {
        'isolateId': _isolateId,
        'isolateName': mainIsolate.name,
        'vmServiceUri': normalizedUri,
      };
    } catch (e) {
      _service = null;
      _isolateId = null;
      _vmServiceUri = null;
      rethrow;
    }
  }

  /// Disconnects from the current VM service.
  Future<void> disconnect({bool clearSession = true}) async {
    if (_service != null) {
      await _service!.dispose();
      _service = null;
    }
    _isolateId = null;
    _vmServiceUri = null;

    if (clearSession) {
      await Session.clear();
    }
  }

  /// Attempts to restore a connection from a saved session.
  Future<bool> restoreSession() async {
    final session = await Session.load();
    if (session == null) {
      return false;
    }

    try {
      await connect(session.vmServiceUri, saveSession: false);
      return true;
    } catch (e) {
      // Session is stale, clear it
      await Session.clear();
      return false;
    }
  }

  /// Ensures we're connected, attempting to restore session if needed.
  Future<void> ensureConnected() async {
    if (isConnected) return;

    if (!await restoreSession()) {
      throw StateError(
        'Not connected to any Flutter app. '
        'Use "marionette connect <vm_service_uri>" first.',
      );
    }
  }

  /// Calls a Marionette extension method on the connected app.
  Future<Map<String, dynamic>> callMarionetteExtension(
    String method, [
    Map<String, dynamic>? args,
  ]) async {
    await ensureConnected();

    final extensionMethod = 'ext.flutter.marionette.$method';

    try {
      final response = await _service!.callServiceExtension(
        extensionMethod,
        isolateId: _isolateId,
        args: args,
      );

      final json = response.json ?? {};

      // Check if the extension itself reported an error
      if (json['status'] == 'Error') {
        final errorMessage = json['error'] as String? ?? 'Unknown error';
        throw MarionetteException.fromError(errorMessage);
      }

      return json;
    } on RPCError catch (e) {
      if (e.code == -32601) {
        throw MarionetteException(
          'Marionette extension "$method" not found. '
          'Ensure the Flutter app has marionette_flutter initialized.',
          code: 'EXTENSION_NOT_FOUND',
        );
      }
      rethrow;
    }
  }

  /// Gets all interactive elements from the widget tree.
  ///
  /// Optionally filter by [type] (e.g., 'Button', 'TextField').
  Future<List<InteractiveElement>> getInteractiveElements({
    String? filter,
  }) async {
    final response = await callMarionetteExtension(
      'interactiveElements',
      filter != null ? {'filter': filter} : null,
    );

    final elementsJson = response['elements'] as List<dynamic>? ?? [];
    return elementsJson
        .map((e) => InteractiveElement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Checks if any loading indicators are present.
  Future<bool> hasLoadingIndicators() async {
    final elements = await getInteractiveElements();
    return _hasLoading(elements);
  }

  bool _hasLoading(List<InteractiveElement> elements) {
    for (final element in elements) {
      if (element.isLoading) return true;
      if (_isLoadingWidget(element.type)) return true;
      if (_hasLoading(element.children)) return true;
    }
    return false;
  }

  bool _isLoadingWidget(String type) {
    final loadingTypes = [
      'CircularProgressIndicator',
      'LinearProgressIndicator',
      'RefreshProgressIndicator',
      'CupertinoActivityIndicator',
      'Shimmer',
      'SkeletonLoader',
    ];
    return loadingTypes.any(
      (t) => type.toLowerCase().contains(t.toLowerCase()),
    );
  }

  /// Checks if any dialogs or popups are present.
  Future<bool> hasDialogs() async {
    final elements = await getInteractiveElements();
    return _hasDialog(elements);
  }

  bool _hasDialog(List<InteractiveElement> elements) {
    for (final element in elements) {
      if (element.isDialog) return true;
      if (_isDialogWidget(element.type)) return true;
      if (_hasDialog(element.children)) return true;
    }
    return false;
  }

  bool _isDialogWidget(String type) {
    final dialogTypes = [
      'AlertDialog',
      'SimpleDialog',
      'Dialog',
      'ModalBarrier',
      'BottomSheet',
      'ModalBottomSheet',
      'Snackbar',
      'PopupMenuButton',
      'DropdownButton',
    ];
    return dialogTypes.any(
      (t) => type.toLowerCase().contains(t.toLowerCase()),
    );
  }

  /// Waits for loading to complete (no loading indicators visible).
  ///
  /// Returns true if loading completed, false if timeout.
  Future<bool> waitForLoading({
    Duration timeout = const Duration(seconds: 30),
    Duration pollInterval = const Duration(milliseconds: 500),
  }) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      if (!await hasLoadingIndicators()) {
        return true;
      }
      await Future<void>.delayed(pollInterval);
    }

    return false;
  }

  /// Taps on an element identified by key, text, or type.
  ///
  /// The matcher precedence is: key > text > type.
  /// At least one of [key], [text], or [type] must be provided.
  Future<Map<String, dynamic>> tap({
    String? key,
    String? text,
    String? type,
  }) async {
    final args = <String, dynamic>{};
    if (key != null) {
      args['key'] = key;
    } else if (text != null) {
      args['text'] = text;
    } else if (type != null) {
      args['type'] = type;
    } else {
      throw ArgumentError(
          'At least one of key, text, or type must be provided');
    }
    return callMarionetteExtension('tap', args);
  }

  /// Enters text into a text field identified by key, text, or type.
  Future<Map<String, dynamic>> enterText(
    String inputText, {
    String? key,
    String? text,
    String? type,
  }) async {
    final args = <String, dynamic>{'input': inputText};
    if (key != null) {
      args['key'] = key;
    } else if (text != null) {
      args['text'] = text;
    } else if (type != null) {
      args['type'] = type;
    } else {
      throw ArgumentError(
          'At least one of key, text, or type must be provided');
    }
    return callMarionetteExtension('enterText', args);
  }

  /// Scrolls to bring an element into view.
  Future<Map<String, dynamic>> scrollTo({
    String? key,
    String? text,
    String? type,
  }) async {
    final args = <String, dynamic>{};
    if (key != null) {
      args['key'] = key;
    } else if (text != null) {
      args['text'] = text;
    } else if (type != null) {
      args['type'] = type;
    } else {
      throw ArgumentError(
          'At least one of key, text, or type must be provided');
    }
    return callMarionetteExtension('scrollTo', args);
  }

  /// Gets application logs.
  Future<List<String>> getLogs({int? limit, String? level}) async {
    final args = <String, dynamic>{};
    if (limit != null) args['limit'] = limit;
    if (level != null) args['level'] = level;

    final response = await callMarionetteExtension(
      'getLogs',
      args.isNotEmpty ? args : null,
    );

    return (response['logs'] as List<dynamic>?)?.cast<String>() ?? [];
  }

  /// Takes a screenshot of the current app state.
  ///
  /// Returns the screenshot as PNG bytes.
  Future<Uint8List> takeScreenshot() async {
    final response = await callMarionetteExtension('takeScreenshots');

    // The response contains 'screenshots' array with base64 encoded images
    final screenshots = response['screenshots'] as List<dynamic>?;
    if (screenshots == null || screenshots.isEmpty) {
      throw StateError('No screenshot data received');
    }

    // Get the first screenshot
    final base64Data = screenshots.first as String?;
    if (base64Data == null) {
      throw StateError('No screenshot data received');
    }

    return base64Decode(base64Data);
  }

  /// Triggers a hot reload of the Flutter app.
  Future<Map<String, dynamic>> hotReload() async {
    await ensureConnected();

    try {
      final response = await _service!.reloadSources(_isolateId!);
      return {
        'success': response.success ?? false,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Gets the current connection status.
  Future<Map<String, dynamic>> getStatus() async {
    final session = await Session.load();

    if (!isConnected && session != null) {
      // Try to restore
      final restored = await restoreSession();
      if (!restored) {
        return {
          'connected': false,
          'staleSession': true,
          'lastUri': session.vmServiceUri,
          'lastConnectedAt': session.connectedAt.toIso8601String(),
        };
      }
    }

    if (!isConnected) {
      return {'connected': false};
    }

    return {
      'connected': true,
      'vmServiceUri': _vmServiceUri,
      'isolateId': _isolateId,
    };
  }
}
