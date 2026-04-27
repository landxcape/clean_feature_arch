# Changelog

## 1.4.5
- **Absolute Import Migration**: Migrated all scaffolding and surgical patching to use fully-qualified `package:project_name/...` imports.
- **Improved Performance**: Standardized import style to improve analyzer efficiency and ensure consistent behavior across deep directory structures.
- **Bug Fix**: Resolved "Depth Paradox" errors caused by inconsistent relative path calculations in nested features.

## 1.4.4
- **Production-Safe Logging**: Enhanced `AppLogger` with `kReleaseMode` detection and a `LogReporter` interface for optional remote error reporting.
- **Error Diagnostics**: Automatic stacktrace capture for error-level diagnostics.
- **Console Silence**: Standardized environment-aware log filtering to ensure local logs are silenced in production builds.

## 1.4.3
- **Rule 8 Compliance**: Converted `AppError` to a `@freezed sealed class` for consistent error handling and logging.
- **API Wrapper Engine**: Added `BaseResponse<T>` generic model and `IBaseResponse` interface to standardize backend envelopes.
- **Enhanced Error Handler**: Updated `ErrorHandler.guard` to automatically check `IBaseResponse.success` and return backend error messages via `AppError.server`.
- **Surgical Paths**: Corrected relative import depths for BLoC, providers, and local data sources.

## 1.4.2
- Feat: Integrated `logger` and `pretty_dio_logger` for professional, production-grade logging.
- Style: Resolved remaining package lints for a perfect quality score.

## 1.4.1
- Fix: Corrected relative import paths and prevented duplicate constructor generation.
- Fix: Ensured idempotent feature registration in `injection_container.dart`.
- Chore: Updated analyzer dependency constraints for version 13.0.0 compatibility.

## 1.4.0
- Feat: Added modular storage system via `storage init` and `storage feature` commands.
- Feat: Implemented surgical code patching for non-destructive feature upgrades.
- Feat: Implemented dynamic presentation folder naming (`bloc/`, `providers/`) based on state management.

## 1.3.1
- Feat: Added `permission` command and `test` command for cross-platform and QA scaffolding.

## 1.3.0
- Feat: Enhanced `init` to generate fully wired production core infrastructure.

## 1.0.0
- Initial release with Absolute Rule Architecture scaffolding and enforcement.
