import 'package:args/command_runner.dart';

import '../services/vm_service_client.dart';
import '../utils/output.dart';

/// Command to trigger a hot reload of the Flutter app.
///
/// Usage: `marionette reload`
class ReloadCommand extends Command<int> {
  @override
  final String name = 'reload';

  @override
  final String description = 'Trigger a hot reload of the Flutter app';

  ReloadCommand() {
    argParser.addFlag(
      'wait-for-loading',
      abbr: 'w',
      help: 'Wait for the app to finish loading after reload',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    final waitForLoading = argResults!['wait-for-loading'] as bool;

    final client = VmServiceClient();

    try {
      await client.ensureConnected();

      final result = await client.hotReload();

      if (waitForLoading) {
        await client.waitForLoading();
        result['loadingComplete'] = true;
      }

      Output.success(
        result,
        message: result['success'] == true
            ? 'Hot reload successful'
            : 'Hot reload completed with warnings',
      );

      return ExitCode.success;
    } on StateError catch (e) {
      Output.error(e.message, code: 'NOT_CONNECTED');
      return ExitCode.connection;
    } catch (e) {
      Output.error('Failed to reload: $e', code: 'RELOAD_ERROR');
      return ExitCode.error;
    } finally {
      await client.disconnect(clearSession: false);
    }
  }
}
