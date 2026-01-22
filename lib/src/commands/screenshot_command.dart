import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

import '../services/vm_service_client.dart';
import '../utils/output.dart';

/// Command to take a screenshot of the current app state.
///
/// Usage: `marionette screenshot [--output <path>]`
class ScreenshotCommand extends Command<int> {
  @override
  final String name = 'screenshot';

  @override
  final String description = 'Take a screenshot of the current app state';

  ScreenshotCommand() {
    argParser
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output file path (default: screenshot_<timestamp>.png)',
      )
      ..addFlag(
        'base64',
        abbr: 'b',
        help: 'Output as base64-encoded string instead of saving to file',
        negatable: false,
      );
  }

  @override
  Future<int> run() async {
    var outputPath = argResults!['output'] as String?;
    final asBase64 = argResults!['base64'] as bool;

    final client = VmServiceClient();

    try {
      await client.ensureConnected();

      final screenshotBytes = await client.takeScreenshot();

      if (asBase64) {
        // Output as base64 string
        final base64String = _bytesToBase64(screenshotBytes);
        Output.success({
          'format': 'base64',
          'mimeType': 'image/png',
          'data': base64String,
          'size': screenshotBytes.length,
        });
      } else {
        // Save to file
        outputPath ??= _generateFilename();
        final absolutePath = path.isAbsolute(outputPath)
            ? outputPath
            : path.join(Directory.current.path, outputPath);

        final file = File(absolutePath);
        await file.writeAsBytes(screenshotBytes);

        Output.success(
          {
            'path': absolutePath,
            'size': screenshotBytes.length,
          },
          message: 'Screenshot saved successfully',
        );
      }

      return ExitCode.success;
    } on StateError catch (e) {
      Output.error(e.message, code: 'NOT_CONNECTED');
      return ExitCode.connection;
    } catch (e) {
      Output.error('Failed to take screenshot: $e', code: 'SCREENSHOT_ERROR');
      return ExitCode.error;
    } finally {
      await client.disconnect(clearSession: false);
    }
  }

  String _generateFilename() {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return 'screenshot_$timestamp.png';
  }

  String _bytesToBase64(List<int> bytes) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final buffer = StringBuffer();

    for (var i = 0; i < bytes.length; i += 3) {
      final b1 = bytes[i];
      final b2 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b3 = i + 2 < bytes.length ? bytes[i + 2] : 0;

      buffer.write(chars[(b1 >> 2) & 0x3F]);
      buffer.write(chars[((b1 << 4) | (b2 >> 4)) & 0x3F]);
      buffer.write(
          i + 1 < bytes.length ? chars[((b2 << 2) | (b3 >> 6)) & 0x3F] : '=');
      buffer.write(i + 2 < bytes.length ? chars[b3 & 0x3F] : '=');
    }

    return buffer.toString();
  }
}
