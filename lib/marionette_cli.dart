/// Marionette CLI - Flutter app interaction via command line.
///
/// This library provides CLI tools for AI assistants to inspect and interact
/// with running Flutter applications via the VM service.
library marionette_cli;

export 'src/commands/connect_command.dart';
export 'src/commands/disconnect_command.dart';
export 'src/commands/elements_command.dart';
export 'src/commands/logs_command.dart';
export 'src/commands/reload_command.dart';
export 'src/commands/screenshot_command.dart';
export 'src/commands/scroll_command.dart';
export 'src/commands/status_command.dart';
export 'src/commands/tap_command.dart';
export 'src/commands/text_command.dart';
export 'src/models/interactive_element.dart';
export 'src/services/vm_service_client.dart';
export 'src/utils/output.dart';
export 'src/utils/session.dart';
