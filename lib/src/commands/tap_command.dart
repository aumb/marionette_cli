import 'package:args/command_runner.dart';

import '../services/vm_service_client.dart';
import '../utils/exceptions.dart';
import '../utils/output.dart';

/// Command to tap on an element.
///
/// Usage:
///   `marionette tap <element_key>` - tap by key
///   `marionette tap --text "Apples"` - tap by visible text
///   `marionette tap --type ElevatedButton` - tap first element of type
class TapCommand extends Command<int> {
  @override
  final String name = 'tap';

  @override
  final String description = 'Tap on an element by key, text, or type';

  @override
  String get invocation => '$name [<element_key>] [options]';

  TapCommand() {
    argParser
      ..addOption(
        'text',
        abbr: 'x',
        help: 'Tap element by visible text (e.g., "Submit", "Apples")',
      )
      ..addOption(
        'type',
        help: 'Tap first element of this widget type (e.g., ElevatedButton)',
      )
      ..addFlag(
        'wait-for-loading',
        abbr: 'w',
        help: 'Wait for loading to complete after tap',
        negatable: false,
      )
      ..addOption(
        'timeout',
        abbr: 't',
        help: 'Timeout in seconds when waiting (default: 30)',
        defaultsTo: '30',
      );
  }

  @override
  Future<int> run() async {
    final elementKey =
        argResults!.rest.isNotEmpty ? argResults!.rest.first : null;
    final textMatch = argResults!['text'] as String?;
    final typeMatch = argResults!['type'] as String?;
    final waitForLoading = argResults!['wait-for-loading'] as bool;
    final timeoutSeconds = int.tryParse(argResults!['timeout'] as String) ?? 30;

    // Must have at least one matcher
    if (elementKey == null && textMatch == null && typeMatch == null) {
      Output.error(
        'Must specify element key, --text, or --type',
        code: 'MISSING_ARGUMENT',
        details: {
          'usage':
              'marionette tap <key> OR marionette tap --text "Label" OR marionette tap --type ElevatedButton',
          'hint': 'Run "marionette elements" first to find available elements',
        },
      );
      return ExitCode.usage;
    }

    final client = VmServiceClient();

    try {
      await client.ensureConnected();

      final result = await client.tap(
        key: elementKey,
        text: textMatch,
        type: typeMatch,
      );

      // Wait for loading if requested
      if (waitForLoading) {
        final loadingComplete = await client.waitForLoading(
          timeout: Duration(seconds: timeoutSeconds),
        );

        result['loadingComplete'] = loadingComplete;
        if (!loadingComplete) {
          result['warning'] = 'Loading did not complete within timeout';
        }
      }

      // Build tapped description
      String tappedDesc;
      if (elementKey != null) {
        tappedDesc = 'key: $elementKey';
      } else if (textMatch != null) {
        tappedDesc = 'text: "$textMatch"';
      } else {
        tappedDesc = 'type: $typeMatch';
      }

      Output.success(
        {
          'tapped': tappedDesc,
          ...result,
        },
        message: 'Successfully tapped on element',
      );

      return ExitCode.success;
    } on MarionetteException catch (e) {
      Output.error(
        e.message,
        code: e.code,
        details: {
          if (elementKey != null) 'key': elementKey,
          if (textMatch != null) 'text': textMatch,
          if (typeMatch != null) 'type': typeMatch,
          'hint': 'Run "marionette elements" to see available elements.',
        },
      );
      return e.code == 'ELEMENT_NOT_FOUND' ? ExitCode.notFound : ExitCode.error;
    } on StateError catch (e) {
      Output.error(e.message, code: 'NOT_CONNECTED');
      return ExitCode.connection;
    } catch (e) {
      Output.error('Failed to tap: $e', code: 'TAP_ERROR');
      return ExitCode.error;
    } finally {
      await client.disconnect(clearSession: false);
    }
  }
}
