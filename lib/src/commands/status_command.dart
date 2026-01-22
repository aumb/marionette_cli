import 'package:args/command_runner.dart';

import '../services/vm_service_client.dart';
import '../utils/output.dart';

/// Command to get current connection status.
///
/// Usage: `marionette status`
class StatusCommand extends Command<int> {
  @override
  final String name = 'status';

  @override
  final String description = 'Get the current connection status';

  @override
  Future<int> run() async {
    final client = VmServiceClient();

    try {
      final status = await client.getStatus();
      Output.success(status);
      return ExitCode.success;
    } catch (e) {
      Output.error('Failed to get status: $e', code: 'STATUS_ERROR');
      return ExitCode.error;
    } finally {
      await client.disconnect(clearSession: false);
    }
  }
}
