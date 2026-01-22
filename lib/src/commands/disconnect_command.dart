import 'package:args/command_runner.dart';

import '../utils/output.dart';
import '../utils/session.dart';

/// Command to disconnect from the currently connected Flutter app.
///
/// Usage: `marionette disconnect`
class DisconnectCommand extends Command<int> {
  @override
  final String name = 'disconnect';

  @override
  final String description =
      'Disconnect from the currently connected Flutter app';

  @override
  Future<int> run() async {
    final sessionExists = await Session.exists();

    if (!sessionExists) {
      Output.error(
        'No active session to disconnect from',
        code: 'NO_SESSION',
      );
      return ExitCode.error;
    }

    await Session.clear();

    Output.success(
      {'disconnected': true},
      message: 'Successfully disconnected and cleared session',
    );

    return ExitCode.success;
  }
}
