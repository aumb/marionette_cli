import 'package:args/command_runner.dart';

import '../services/vm_service_client.dart';
import '../utils/exceptions.dart';
import '../utils/output.dart';

/// Command to enter text into a text field.
///
/// Usage:
///   `marionette text <element_key> "<text>"` - by key
///   `marionette text --label "Email" "<text>"` - by label text
class TextCommand extends Command<int> {
  @override
  final String name = 'text';

  @override
  final String description = 'Enter text into a text field';

  @override
  String get invocation => '$name [<element_key>] "<text>" [options]';

  TextCommand() {
    argParser
      ..addOption(
        'label',
        abbr: 'l',
        help: 'Find text field by its label text',
      )
      ..addOption(
        'type',
        help: 'Find text field by widget type (e.g., TextFormField)',
      )
      ..addFlag(
        'clear',
        abbr: 'c',
        help: 'Clear existing text before entering new text',
        negatable: false,
      )
      ..addFlag(
        'submit',
        abbr: 's',
        help: 'Submit/confirm the text entry (press Enter)',
        negatable: false,
      );
  }

  @override
  Future<int> run() async {
    final args = argResults!.rest;
    final labelMatch = argResults!['label'] as String?;
    final typeMatch = argResults!['type'] as String?;
    // ignore: unused_local_variable
    final clear = argResults!['clear'] as bool;
    // ignore: unused_local_variable
    final submit = argResults!['submit'] as bool;

    // Parse key and text from positional arguments
    String? elementKey;
    String? text;

    if (labelMatch != null || typeMatch != null) {
      // Using --label or --type, text is first positional arg
      if (args.isEmpty) {
        Output.error(
          'Missing required argument: text',
          code: 'MISSING_ARGUMENT',
          details: {
            'usage': 'marionette text --label "Email" "user@example.com"',
          },
        );
        return ExitCode.usage;
      }
      text = args.join(' ');
    } else {
      // Using key, need key + text
      if (args.length < 2) {
        Output.error(
          'Missing arguments. Use: <key> "<text>" OR --label "<text>"',
          code: 'MISSING_ARGUMENT',
          details: {
            'usage': 'marionette text <element_key> "<text>"',
            'alt': 'marionette text --label "Field Label" "<text>"',
            'example': 'marionette text email_field "user@example.com"',
          },
        );
        return ExitCode.usage;
      }
      elementKey = args[0];
      text = args.sublist(1).join(' ');
    }

    final client = VmServiceClient();

    try {
      await client.ensureConnected();

      final result = await client.enterText(
        text,
        key: elementKey,
        text: labelMatch,
        type: typeMatch,
      );

      // Build target description
      String targetDesc;
      if (elementKey != null) {
        targetDesc = 'key: $elementKey';
      } else if (labelMatch != null) {
        targetDesc = 'label: "$labelMatch"';
      } else {
        targetDesc = 'type: $typeMatch';
      }

      Output.success(
        {
          'element': targetDesc,
          'text': text,
          ...result,
        },
        message: 'Successfully entered text',
      );

      return ExitCode.success;
    } on MarionetteException catch (e) {
      Output.error(
        e.message,
        code: e.code,
        details: {
          if (elementKey != null) 'key': elementKey,
          if (labelMatch != null) 'label': labelMatch,
          if (typeMatch != null) 'type': typeMatch,
          'hint':
              'Run "marionette elements --filter TextField" to find text fields',
        },
      );
      return e.code == 'ELEMENT_NOT_FOUND' ? ExitCode.notFound : ExitCode.error;
    } on StateError catch (e) {
      Output.error(e.message, code: 'NOT_CONNECTED');
      return ExitCode.connection;
    } catch (e) {
      Output.error('Failed to enter text: $e', code: 'TEXT_ERROR');
      return ExitCode.error;
    } finally {
      await client.disconnect(clearSession: false);
    }
  }
}
