import 'package:args/command_runner.dart';

import '../services/vm_service_client.dart';
import '../utils/output.dart';

/// Command to scroll to bring an element into view.
///
/// Usage:
///   `marionette scroll <element_key>` - by key
///   `marionette scroll --text "Apples"` - by visible text
class ScrollCommand extends Command<int> {
  @override
  final String name = 'scroll';

  @override
  final String description = 'Scroll to bring an element into view';

  @override
  String get invocation => '$name [<element_key>] [options]';

  ScrollCommand() {
    argParser
      ..addOption(
        'text',
        abbr: 'x',
        help: 'Scroll to element by visible text',
      )
      ..addOption(
        'type',
        help: 'Scroll to first element of this widget type',
      )
      ..addOption(
        'alignment',
        abbr: 'a',
        help:
            'Alignment of element after scroll (0.0 = top, 0.5 = center, 1.0 = bottom)',
        defaultsTo: '0.5',
      );
  }

  @override
  Future<int> run() async {
    final elementKey =
        argResults!.rest.isNotEmpty ? argResults!.rest.first : null;
    final textMatch = argResults!['text'] as String?;
    final typeMatch = argResults!['type'] as String?;

    // Must have at least one matcher
    if (elementKey == null && textMatch == null && typeMatch == null) {
      Output.error(
        'Must specify element key, --text, or --type',
        code: 'MISSING_ARGUMENT',
        details: {
          'usage':
              'marionette scroll <key> OR marionette scroll --text "Label"',
          'hint': 'Run "marionette elements" first to find element keys',
        },
      );
      return ExitCode.usage;
    }

    final client = VmServiceClient();

    try {
      await client.ensureConnected();

      final result = await client.scrollTo(
        key: elementKey,
        text: textMatch,
        type: typeMatch,
      );

      // Build target description
      String targetDesc;
      if (elementKey != null) {
        targetDesc = 'key: $elementKey';
      } else if (textMatch != null) {
        targetDesc = 'text: "$textMatch"';
      } else {
        targetDesc = 'type: $typeMatch';
      }

      Output.success(
        {
          'scrolledTo': targetDesc,
          ...result,
        },
        message: 'Successfully scrolled to element',
      );

      return ExitCode.success;
    } on StateError catch (e) {
      if (e.message.contains('not found') || e.message.contains('No element')) {
        Output.error(
          'Element not found',
          code: 'ELEMENT_NOT_FOUND',
          details: {
            if (elementKey != null) 'key': elementKey,
            if (textMatch != null) 'text': textMatch,
            if (typeMatch != null) 'type': typeMatch,
            'hint': 'Run "marionette elements" to see available elements',
          },
        );
        return ExitCode.notFound;
      }
      Output.error(e.message, code: 'NOT_CONNECTED');
      return ExitCode.connection;
    } catch (e) {
      Output.error('Failed to scroll: $e', code: 'SCROLL_ERROR');
      return ExitCode.error;
    } finally {
      await client.disconnect(clearSession: false);
    }
  }
}
