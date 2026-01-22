# Marionette CLI Skill

## Overview

Marionette CLI enables you to inspect and interact with running Flutter applications via the VM service. Use this skill when you need to:
- Verify UI changes work correctly
- Test user flows and interactions
- Debug UI issues
- Take screenshots for documentation

## Prerequisites

1. The Flutter app must be running in **debug mode**
2. The app must have `marionette_flutter` package integrated
3. `marionette` CLI must be installed and available in PATH

## Connection

Before any interaction, connect to the running Flutter app:

```bash
# Find the VM service URI in flutter run output:
# "The Flutter DevTools debugger ... available at: http://127.0.0.1:9101?uri=ws://127.0.0.1:9101/ws"

marionette connect ws://127.0.0.1:XXXXX/ws
```

The session is saved to `.marionette_session` in the current directory.

---

## ⚠️ CRITICAL RULES

> **NEVER chain commands with `&&` or `;`**. Run each command separately and verify the output before proceeding.

### Why This Matters

1. **Elements change after every action** - The `back_button` that exists on screen A doesn't exist on screen B
2. **You must verify each step succeeded** - Check for `"success": true` in output
3. **Element keys are screen-specific** - Always run `elements` after navigation to discover new keys

### Correct Pattern

```bash
# Step 1: Tap a card
marionette tap --text "Apples"
# VERIFY: Check output shows success

# Step 2: Wait and discover new screen's elements  
marionette elements --wait-for-loading
# VERIFY: Look at output to find the back button key (might be "back", "nav_back", "close_button", etc.)

# Step 3: Take screenshot
marionette screenshot --output apples.png
# VERIFY: Check output shows file saved

# Step 4: Tap back (using key found in step 2!)
marionette tap back  # Use the actual key from elements output
# VERIFY: Check success
```

### ❌ WRONG - Never Do This

```bash
# WRONG: Chaining without verification
marionette tap card_1 && marionette elements && marionette tap back_button
```

This fails because:
- You don't verify `card_1` exists before tapping
- You don't read the `elements` output to find the actual back button key
- `back_button` might not be the correct key for this app

---

## Core Workflow

### ALWAYS Start with `elements`

Before ANY interaction, discover what's on screen:

```bash
marionette elements --check-dialogs
```

This tells you:
- Available element keys for interaction
- Whether loading indicators are present
- Whether dialogs/popups are blocking the UI

### Handle Loading States

If output includes `"warning": "Loading indicators detected..."`:

```bash
marionette elements --wait-for-loading --timeout 30
```

**After any action that triggers loading** (tap, navigation, form submission):

```bash
marionette tap submit_button --wait-for-loading
marionette elements --wait-for-loading
```

### Handle Dialogs First

If `"dialogDetected": true` appears:

1. Find the dialog's action buttons in elements list
2. Tap the appropriate button (OK, Cancel, Dismiss)
3. Run `elements` again to verify dialog is gone
4. Then interact with background elements

```bash
# Example: dismiss a dialog
marionette tap dialog_ok_button
marionette elements
```

---

## Commands Reference

### Discovery

```bash
marionette elements                      # All elements
marionette elements --filter Button      # Only buttons
marionette elements --filter TextField   # Only text fields
marionette elements --compact            # Minimal output
marionette elements --check-dialogs      # Include dialog detection
marionette elements --wait-for-loading   # Wait for loading first
```

### Interaction

**By Key (requires ValueKey in app):**
```bash
marionette tap login_button
marionette text email_field "user@example.com"
marionette scroll footer_section
```

**By Visible Text (most flexible - finds nested Text widgets):**
```bash
marionette tap --text "Apples"              # Tap element with text "Apples"
marionette tap --text "Submit"              # Tap button with "Submit" label
marionette scroll --text "See More"         # Scroll to element with text
marionette text --label "Email" "user@example.com"  # Enter text in field with label
```

**By Widget Type:**
```bash
marionette tap --type ElevatedButton        # Tap first ElevatedButton
marionette scroll --type Card               # Scroll to first Card
```

**With wait after action:**
```bash
marionette tap --text "Submit" --wait-for-loading
```

### Debugging

```bash
marionette screenshot                    # Save to file
marionette screenshot --output name.png  # Custom filename
marionette screenshot --base64           # Output as base64

marionette logs                          # Get app logs
marionette logs --limit 20               # Last 20 entries
marionette logs --level SEVERE           # Errors only

marionette reload                        # Hot reload
marionette reload --wait-for-loading     # Reload and wait
```

### Session

```bash
marionette status      # Check connection
marionette disconnect  # Clear session
```

---

## Standard Interaction Pattern

Follow this pattern for reliable interactions:

```bash
# 1. Check current UI state
marionette elements --check-dialogs

# 2. Handle any dialogs (if dialogDetected is true)
marionette tap dialog_dismiss_button

# 3. Wait for loading (if warning present)
marionette elements --wait-for-loading

# 4. Perform the interaction
marionette tap login_button

# 5. Wait and verify result
marionette elements --wait-for-loading --check-dialogs
```

---

## Common Patterns

### Login Flow

```bash
marionette elements --filter TextField
marionette text email_field "user@example.com"
marionette text password_field "secret123"
marionette tap login_button --wait-for-loading
marionette elements  # Verify dashboard appears
```

### Navigation

```bash
marionette tap settings_button
marionette elements --wait-for-loading  # ALWAYS refresh after navigation
# Now you see the new screen's elements
```

### Form Submission

```bash
# Fill form
marionette text name_field "John Doe"
marionette text email_field "john@example.com"

# Submit and verify
marionette tap submit_button --wait-for-loading
marionette elements  # Should show success or next screen
```

### Error Recovery

**If element not found (ELEMENT_NOT_FOUND):**

1. **Run `elements` to get the current list**:
   ```bash
   marionette elements
   ```

2. **Search for similar keys** - Look for elements with partial matches:
   - If you tried `login_button`, look for keys containing `login`, `submit`, `sign_in`
   - If you tried `email_field`, look for keys containing `email`, `user`, `username`
   - Check the `label` field for human-readable text that matches your intent

3. **Try the matching element**:
   ```bash
   marionette tap <found_similar_key>
   ```

4. **If still not found, maybe scroll is needed**:
   ```bash
   marionette scroll <element_key>
   marionette tap <element_key>
   ```

**Example - finding a similar button:**
```bash
# Tried: marionette tap login_button -> ELEMENT_NOT_FOUND

# Step 1: Get elements
marionette elements --filter Button

# Step 2: Look for matches in output - found "signIn_btn" with label "Log In"

# Step 3: Use the correct key
marionette tap signIn_btn
```

**If loading never completes:**
```bash
marionette screenshot --output debug.png  # See current state
marionette logs --level SEVERE            # Check for errors
```

**If connection lost:**
```bash
marionette status                          # Check connection
marionette connect ws://127.0.0.1:XXXXX/ws # Reconnect with fresh URI
```

---

## Widget Types

| Type | Examples | Interaction |
|------|----------|-------------|
| Buttons | `ElevatedButton`, `TextButton`, `IconButton` | `tap` |
| Text inputs | `TextField`, `TextFormField` | `text` |
| Toggles | `Checkbox`, `Switch`, `Radio` | `tap` |
| Containers | `ListTile`, `Card`, `InkWell` | `tap` |
| Loading | `CircularProgressIndicator`, `Shimmer` | Wait |
| Dialogs | `AlertDialog`, `BottomSheet` | Handle first |

---

## Best Practices

✅ **DO**:
- Run `elements` before every interaction sequence
- Use `--wait-for-loading` after async operations
- Use `--check-dialogs` to detect popups
- Handle dialogs before background interactions
- Verify results with another `elements` call

❌ **DON'T**:
- Assume element keys persist across screens
- Interact while loading is in progress
- Ignore dialog warnings
- Skip verification after actions

---

## Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| `NOT_CONNECTED` | No connection | Run `marionette connect <uri>` |
| `ELEMENT_NOT_FOUND` | Key doesn't exist | Run `elements` and check keys |
| `LOADING_TIMEOUT` | Loading didn't complete | Check app for infinite loading |
| `CONNECTION_FAILED` | Can't reach app | Ensure app is running in debug mode |
