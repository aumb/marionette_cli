import 'package:args/command_runner.dart';

import '../services/vm_service_client.dart';
import '../utils/output.dart';

/// Command to get interactive elements from the widget tree.
///
/// Usage: `marionette elements [--filter <type>] [--wait-for-loading]`
///
/// This is the primary command for discovering what can be interacted with.
/// AI models should ALWAYS run this command first to understand the current
/// UI state before attempting any interactions.
class ElementsCommand extends Command<int> {
  @override
  final String name = 'elements';

  @override
  final String description = 'Get interactive elements from the widget tree';

  ElementsCommand() {
    argParser
      ..addOption(
        'filter',
        abbr: 'f',
        help: 'Filter elements by type (e.g., Button, TextField)',
      )
      ..addFlag(
        'wait-for-loading',
        abbr: 'w',
        help:
            'Wait for loading indicators to complete before fetching elements',
        negatable: false,
      )
      ..addOption(
        'timeout',
        abbr: 't',
        help: 'Timeout in seconds when waiting for loading (default: 30)',
        defaultsTo: '30',
      )
      ..addFlag(
        'check-dialogs',
        abbr: 'd',
        help: 'Include information about detected dialogs/popups',
        negatable: false,
      )
      ..addFlag(
        'compact',
        abbr: 'c',
        help: 'Output compact element format (keys and types only)',
        negatable: false,
      );
  }

  @override
  Future<int> run() async {
    final filter = argResults!['filter'] as String?;
    final waitForLoading = argResults!['wait-for-loading'] as bool;
    final timeoutSeconds = int.tryParse(argResults!['timeout'] as String) ?? 30;
    final checkDialogs = argResults!['check-dialogs'] as bool;
    final compact = argResults!['compact'] as bool;

    final client = VmServiceClient();

    try {
      await client.ensureConnected();

      // Wait for loading if requested
      if (waitForLoading) {
        final loadingComplete = await client.waitForLoading(
          timeout: Duration(seconds: timeoutSeconds),
        );

        if (!loadingComplete) {
          Output.error(
            'Timeout waiting for loading to complete',
            code: 'LOADING_TIMEOUT',
            details: {
              'timeoutSeconds': timeoutSeconds,
              'hint': 'The app may have a slow or indefinite loading state',
            },
          );
          return ExitCode.timeout;
        }
      }

      // Check for loading indicators
      final hasLoading = await client.hasLoadingIndicators();
      final hasDialogs = checkDialogs ? await client.hasDialogs() : null;

      // Get elements
      final elements = await client.getInteractiveElements(filter: filter);

      final responseData = <String, dynamic>{
        if (hasLoading)
          'warning':
              'Loading indicators detected - UI may change. Consider using --wait-for-loading',
        if (hasDialogs == true) 'dialogDetected': true,
        if (hasDialogs == true)
          'dialogHint':
              'A dialog or popup is present. Handle it before interacting with background elements.',
        'elements': compact
            ? elements
                .map((e) => {
                      'key': e.key,
                      'type': e.type,
                      if (e.label != null) 'label': e.label,
                      'enabled': e.isEnabled,
                    })
                .toList()
            : elements.map((e) => e.toJson()).toList(),
      };

      Output.list(
        'elements',
        responseData['elements'] as List<dynamic>,
        message: hasLoading
            ? 'Elements retrieved (loading in progress)'
            : 'Elements retrieved successfully',
      );

      // Add warnings if present
      if (hasLoading || hasDialogs == true) {
        // Re-output with warnings
        Output.success({
          ...responseData,
          'count': elements.length,
        });
      }

      return ExitCode.success;
    } on StateError catch (e) {
      Output.error(e.message, code: 'NOT_CONNECTED');
      return ExitCode.connection;
    } catch (e) {
      Output.error('Failed to get elements: $e', code: 'ELEMENTS_ERROR');
      return ExitCode.error;
    } finally {
      await client.disconnect(clearSession: false);
    }
  }
}
