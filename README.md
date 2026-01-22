# Marionette CLI

A CLI tool for inspecting and interacting with running Flutter applications via the VM service. Useful for testing, automation, and enabling AI assistants to interact with your app.

> **For AI Assistants**: See [`SKILL.md`](./SKILL.md) for detailed usage instructions.

## Installation

### Global Installation (Recommended)

```bash
dart pub global activate --source path /path/to/marionette_cli
```

### From Source

```bash
cd marionette_cli
dart pub get
dart compile exe bin/marionette.dart -o marionette
# Add to PATH or use ./marionette
```

## Quick Start

1. **Run your Flutter app** in debug mode:
   ```bash
   flutter run
   ```

2. **Find the VM service URI** in the console output:
   ```
   The Flutter DevTools debugger and profiler is available at: 
   http://127.0.0.1:9101?uri=ws://127.0.0.1:9101/ws
   ```
   Use the `ws://...` part.

3. **Connect**:
   ```bash
   marionette connect ws://127.0.0.1:9101/ws
   ```

4. **Explore elements**:
   ```bash
   marionette elements
   ```

5. **Interact**:
   ```bash
   marionette tap login_button
   marionette text email_field "user@example.com"
   ```

## Commands

### `connect`
Connect to a running Flutter app via VM service.

```bash
marionette connect <vm_service_uri>
marionette connect ws://127.0.0.1:9101/ws
```

**Output:**
```json
{"success": true, "message": "Successfully connected to Flutter app", "isolateId": "isolates/123", "vmServiceUri": "ws://127.0.0.1:9101/ws"}
```

### `disconnect`
Disconnect from the current app and clear session.

```bash
marionette disconnect
```

### `status`
Check current connection status.

```bash
marionette status
```

**Output:**
```json
{"success": true, "connected": true, "vmServiceUri": "ws://127.0.0.1:9101/ws", "isolateId": "isolates/123"}
```

### `elements`
Get interactive elements from the widget tree.

```bash
marionette elements                         # All elements
marionette elements --filter Button         # Only buttons
marionette elements --wait-for-loading      # Wait for loading to complete first
marionette elements --check-dialogs         # Include dialog detection info
marionette elements --compact               # Compact output format
```

**Options:**
- `--filter, -f <type>` - Filter by widget type
- `--wait-for-loading, -w` - Wait for loading indicators to complete
- `--timeout, -t <seconds>` - Timeout for wait operations (default: 30)
- `--check-dialogs, -d` - Check for dialogs/popups
- `--compact, -c` - Compact output format

**Output:**
```json
{
  "success": true,
  "elements": [
    {"key": "login_button", "type": "ElevatedButton", "label": "Login", "isEnabled": true, "isVisible": true},
    {"key": "email_field", "type": "TextField", "label": "Email", "isEnabled": true, "isVisible": true},
    {"key": "password_field", "type": "TextField", "label": "Password", "isEnabled": true, "isVisible": true}
  ],
  "count": 3
}
```

**With loading detection:**
```json
{
  "success": true,
  "warning": "Loading indicators detected - UI may change. Consider using --wait-for-loading",
  "elements": [...],
  "count": 5
}
```

**With dialog detection:**
```json
{
  "success": true,
  "dialogDetected": true,
  "dialogHint": "A dialog or popup is present. Handle it before interacting with background elements.",
  "elements": [...],
  "count": 3
}
```

### `tap`
Tap on an element.

```bash
marionette tap <element_key>
marionette tap login_button
marionette tap submit_btn --wait-for-loading
```

**Options:**
- `--wait-for-loading, -w` - Wait for loading to complete after tap
- `--timeout, -t <seconds>` - Timeout for wait operations (default: 30)

**Output:**
```json
{"success": true, "message": "Successfully tapped on element", "tapped": "login_button"}
```

### `text`
Enter text into a text field.

```bash
marionette text <element_key> "<text>"
marionette text email_field "user@example.com"
marionette text password_field "secret123"
```

**Options:**
- `--clear, -c` - Clear existing text first
- `--submit, -s` - Submit after entering text

**Output:**
```json
{"success": true, "message": "Successfully entered text", "element": "email_field", "text": "user@example.com"}
```

### `scroll`
Scroll to bring an element into view.

```bash
marionette scroll <element_key>
marionette scroll footer_section
```

**Output:**
```json
{"success": true, "message": "Successfully scrolled to element", "scrolledTo": "footer_section"}
```

### `logs`
Get application logs.

```bash
marionette logs
marionette logs --limit 50
marionette logs --level SEVERE
```

**Options:**
- `--limit, -l <count>` - Maximum number of logs
- `--level <level>` - Filter by level (INFO, WARNING, SEVERE)

**Output:**
```json
{
  "success": true,
  "logs": ["2024-01-15 10:30:00 [INFO] User logged in", "2024-01-15 10:30:05 [INFO] Loading dashboard"],
  "count": 2
}
```

### `screenshot`
Capture a screenshot.

```bash
marionette screenshot                       # Save to file
marionette screenshot --output login.png    # Custom filename
marionette screenshot --base64              # Output as base64
```

**Options:**
- `--output, -o <path>` - Output file path
- `--base64, -b` - Output as base64 string

**File Output:**
```json
{"success": true, "message": "Screenshot saved successfully", "path": "/path/to/screenshot_2024-01-15T10-30-00.png", "size": 123456}
```

**Base64 Output:**
```json
{"success": true, "format": "base64", "mimeType": "image/png", "data": "iVBORw0KGgo...", "size": 123456}
```

### `reload`
Trigger a hot reload.

```bash
marionette reload
marionette reload --wait-for-loading
```

**Output:**
```json
{"success": true, "message": "Hot reload successful"}
```

## Global Options

- `--pretty, -p` - Format JSON output with indentation (place before command)
- `--help, -h` - Show help

```bash
marionette --pretty elements
```

## Error Codes

| Code | Exit Code | Description |
|------|-----------|-------------|
| `MISSING_ARGUMENT` | 64 | Required argument not provided |
| `CONNECTION_FAILED` | 69 | Failed to connect to VM service |
| `NOT_CONNECTED` | 69 | No active connection, use `connect` first |
| `ELEMENT_NOT_FOUND` | 70 | Element with given key not found |
| `LOADING_TIMEOUT` | 75 | Timeout waiting for loading to complete |
| `UNKNOWN_ERROR` | 1 | Unexpected error |

## Copilot / AI Assistant Integration

To enable Copilot or other AI assistants to use Marionette CLI with your Flutter project:

### Step 1: Copy the Skill File

Copy [`SKILL.md`](./SKILL.md) from this package to your Flutter project:

```bash
# Option A: GitHub Copilot location
mkdir -p .github/skills
cp /path/to/marionette_cli/SKILL.md .github/skills/marionette.md

# Option B: Generic agent location
mkdir -p .agent/skills
cp /path/to/marionette_cli/SKILL.md .agent/skills/marionette.md
```

### Step 2: Reference in Copilot Instructions

Create or update `.github/copilot-instructions.md` in your project:

```markdown
# Copilot Instructions

## Available Skills

When testing or verifying UI changes in this Flutter app, use the Marionette CLI skill:

- See [.github/skills/marionette.md](.github/skills/marionette.md) for full instructions

## Quick Reference

1. Connect: `marionette connect ws://127.0.0.1:XXXXX/ws`
2. Discover elements: `marionette elements --check-dialogs`
3. Interact: `marionette tap <key>` or `marionette text <key> "value"`
4. Verify: `marionette elements --wait-for-loading`

Always run `elements` before any interaction to discover available widgets.
```

### Step 3: Add to .gitignore

```bash
echo ".marionette_session" >> .gitignore
```

---

## AI Assistant Integration

For AI assistants (Copilot, ChatGPT, Claude, etc.), see [`SKILL.md`](./SKILL.md) for:
- Step-by-step usage instructions
- Critical rules for reliable interactions
- Error recovery patterns
- Text-based element matching

## Session Persistence

After connecting, the session is saved to `.marionette_session` in the **current directory** (your project root). Subsequent commands will reconnect as needed:

```bash
marionette connect ws://127.0.0.1:9101/ws  # Saves session to ./.marionette_session
# ... later ...
marionette elements  # Auto-reconnects using saved session
marionette tap login_button  # Still works
```

> **Tip**: Add `.marionette_session` to your `.gitignore` file.

To check session status:
```bash
marionette status
```

To clear session:
```bash
marionette disconnect
```

## Requirements

- Dart SDK 3.0+
- Flutter app running in **debug** or **profile** mode
- Flutter app should have `marionette_flutter` package for full functionality

## Flutter App Setup

For the CLI to work with your Flutter app, the app must have `marionette_flutter` integrated:

```yaml
# pubspec.yaml
dependencies:
  marionette_flutter: ^0.2.4
```

```dart
// main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

void main() {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  runApp(const MyApp());
}
```

## Troubleshooting

### "Not connected to any Flutter app"
Run `marionette connect <uri>` with the VM service URI from your `flutter run` output.

### "Marionette extension not found"
Ensure your Flutter app has `marionette_flutter` initialized. See [Flutter App Setup](#flutter-app-setup).

### Element not found
1. Run `marionette elements` to see available elements
2. Check if you need to scroll: `marionette scroll <key>`
3. Ensure the element is visible and not obscured by a dialog

### Connection refused
1. Ensure the Flutter app is running in debug mode
2. Check the VM service URI is correct
3. Try restarting the Flutter app

### Loading never completes
1. Check for infinite loading states in your app
2. Use `marionette screenshot` to visualize current state
3. Check `marionette logs` for errors

## License

MIT License
