import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:marionette_cli/src/commands/connect_command.dart';
import 'package:marionette_cli/src/commands/disconnect_command.dart';
import 'package:marionette_cli/src/commands/elements_command.dart';
import 'package:marionette_cli/src/commands/logs_command.dart';
import 'package:marionette_cli/src/commands/reload_command.dart';
import 'package:marionette_cli/src/commands/screenshot_command.dart';
import 'package:marionette_cli/src/commands/scroll_command.dart';
import 'package:marionette_cli/src/commands/status_command.dart';
import 'package:marionette_cli/src/commands/tap_command.dart';
import 'package:marionette_cli/src/commands/text_command.dart';
import 'package:marionette_cli/src/utils/output.dart';

/// Marionette CLI - Flutter app interaction from the command line.
///
/// This tool enables AI assistants to inspect and interact with running
/// Flutter applications via the VM service, without requiring MCP servers.
Future<void> main(List<String> arguments) async {
  // Handle global flags
  if (arguments.contains('--pretty') || arguments.contains('-p')) {
    Output.prettyPrint = true;
    arguments = arguments.where((a) => a != '--pretty' && a != '-p').toList();
  }

  final runner = CommandRunner<int>(
    'marionette',
    'CLI tool for Flutter app interaction - inspect and control running Flutter apps.\n\n'
        'Global flags:\n'
        '  --pretty, -p    Format JSON output with indentation\n\n'
        'Quick start:\n'
        '  1. Run your Flutter app in debug mode\n'
        '  2. Find the VM service URI (ws://127.0.0.1:XXXXX/ws)\n'
        '  3. marionette connect <uri>\n'
        '  4. marionette elements\n'
        '  5. marionette tap <element_key>',
  )
    ..addCommand(ConnectCommand())
    ..addCommand(DisconnectCommand())
    ..addCommand(StatusCommand())
    ..addCommand(ElementsCommand())
    ..addCommand(TapCommand())
    ..addCommand(TextCommand())
    ..addCommand(ScrollCommand())
    ..addCommand(LogsCommand())
    ..addCommand(ScreenshotCommand())
    ..addCommand(ReloadCommand());

  try {
    final exitCode = await runner.run(arguments) ?? ExitCode.success;
    exit(exitCode);
  } on UsageException catch (e) {
    Output.error(
      e.message,
      code: 'USAGE_ERROR',
      details: {'usage': e.usage},
    );
    exit(ExitCode.usage);
  } catch (e) {
    Output.error('Unexpected error: $e', code: 'UNKNOWN_ERROR');
    exit(ExitCode.error);
  }
}
