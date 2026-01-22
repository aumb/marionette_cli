import 'dart:io';

import 'package:args/command_runner.dart';

import '../services/vm_service_client.dart';
import '../utils/output.dart';

/// Command to connect to a running Flutter app via VM service.
///
/// Usage: `marionette connect <vm_service_uri>`
///
/// The VM service URI can be found in the Flutter debug console output.
/// It typically looks like: `ws://127.0.0.1:XXXXX/ws`
class ConnectCommand extends Command<int> {
  @override
  final String name = 'connect';

  @override
  final String description = 'Connect to a running Flutter app via VM service';

  @override
  String get invocation => '$name <vm_service_uri>';

  ConnectCommand() {
    argParser.addFlag(
      'no-save',
      help: 'Do not save the session for subsequent commands',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      Output.error(
        'Missing required argument: vm_service_uri',
        code: 'MISSING_ARGUMENT',
        details: {
          'usage': 'marionette connect <vm_service_uri>',
          'example': 'marionette connect ws://127.0.0.1:9101/ws',
          'hint':
              'Find the URI in your flutter run output or DevTools connection info',
        },
      );
      return ExitCode.usage;
    }

    final uri = argResults!.rest.first;
    final saveSession = !(argResults!['no-save'] as bool);

    final client = VmServiceClient();

    try {
      final result = await client.connect(uri, saveSession: saveSession);

      Output.success(
        result,
        message: 'Successfully connected to Flutter app',
      );

      return ExitCode.success;
    } on SocketException catch (e) {
      Output.error(
        'Failed to connect: ${e.message}',
        code: 'CONNECTION_FAILED',
        details: {
          'uri': uri,
          'hint': 'Ensure the Flutter app is running in debug mode',
        },
      );
      return ExitCode.connection;
    } on StateError catch (e) {
      Output.error(e.message, code: 'STATE_ERROR');
      return ExitCode.error;
    } catch (e) {
      Output.error(
        'Unexpected error: $e',
        code: 'UNKNOWN_ERROR',
      );
      return ExitCode.error;
    } finally {
      await client.disconnect(clearSession: false);
    }
  }
}
