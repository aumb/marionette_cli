# Changelog

## 0.1.1

### Fixed
- Fixed error response handling - CLI now properly detects `status: Error` from marionette_flutter
- Error responses now correctly output `{"success": false, ...}` instead of incorrectly showing success

### Added
- `MarionetteException` class for structured error handling with error codes

## 0.1.0

- Initial release
- Core commands: `connect`, `disconnect`, `elements`, `tap`, `text`, `scroll`, `logs`, `screenshot`, `reload`, `status`
- JSON output format for AI model integration
- Session persistence for seamless command chaining
- Comprehensive error handling with exit codes
