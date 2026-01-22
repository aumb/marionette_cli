import 'package:args/command_runner.dart';

import '../services/vm_service_client.dart';
import '../utils/output.dart';

/// Command to get application logs.
///
/// Usage: `marionette logs [--limit <count>] [--level <level>]`
class LogsCommand extends Command<int> {
  @override
  final String name = 'logs';

  @override
  final String description = 'Get application logs';

  LogsCommand() {
    argParser
      ..addOption(
        'limit',
        abbr: 'l',
        help: 'Maximum number of log entries to retrieve',
      )
      ..addOption(
        'level',
        help: 'Filter by log level (e.g., INFO, WARNING, SEVERE)',
      );
  }

  @override
  Future<int> run() async {
    final limitStr = argResults!['limit'] as String?;
    final limit = limitStr != null ? int.tryParse(limitStr) : null;
    final level = argResults!['level'] as String?;

    final client = VmServiceClient();

    try {
      await client.ensureConnected();

      final logs = await client.getLogs(limit: limit, level: level);

      Output.list(
        'logs',
        logs,
        message: logs.isEmpty
            ? 'No logs found. Ensure your app uses the logging package.'
            : 'Retrieved ${logs.length} log entries',
      );

      return ExitCode.success;
    } on StateError catch (e) {
      Output.error(e.message, code: 'NOT_CONNECTED');
      return ExitCode.connection;
    } catch (e) {
      Output.error('Failed to get logs: $e', code: 'LOGS_ERROR');
      return ExitCode.error;
    } finally {
      await client.disconnect(clearSession: false);
    }
  }
}
