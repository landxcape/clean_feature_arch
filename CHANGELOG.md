# Changelog

## 1.4.9
- Docs: Refactored entire changelog for technical clarity and professional tone.
- Docs: Verified and aligned historical version summaries with official publication records.

## 1.4.8
- Refactor: Renamed `lib/core/localization/app_strings.dart` to match `app_` prefix pattern.
- Feat: Implemented getters in `AppStrings` to support reactive localization updates without app restarts.
- Feat: Added `en-US.json` and `ne-NP.json` sample files to `assets/translations/`.
- Docs: Updated architecture guides with resource suite and localization details.

## 1.4.7
- Fix: Resolved all remaining package lints and formatting issues to improve quality score.
- Style: Enforced mandatory curly braces across all flow control structures in the generator logic.
- Fix: Finalized absolute path resolution for all core resource templates.

## 1.4.6
- Feat: Added standard asset directory structure for images, icons, fonts, and animations.
- Feat: Integrated `easy_localization` with centralized string management.
- Feat: Added `BuildContext` extensions for theme, media query, and localization access.
- Feat: Added responsive scaling utilities for cross-device UI consistency.

## 1.4.5
- Refactor: Migrated all scaffolding and surgical patching to use fully-qualified package imports.
- Fix: Resolved relative path depth issues in nested feature structures.

## 1.4.4
- Feat: Added `LogReporter` interface and optional production error reporting hook.
- Feat: Implemented automatic stacktrace capture for error-level logging.
- Refactor: Standardized environment-aware log filtering.

## 1.4.3
- Refactor: Converted `AppError` to a Freezed sealed class for standardized diagnostics.
- Feat: Added `BaseResponse<T>` generic model and `IBaseResponse` interface.
- Fix: Enhanced `ErrorHandler.guard` to support automatic backend error message extraction.

## 1.4.2
- Feat: Integrated `logger` and `pretty_dio_logger` for production-grade logging.
- Fix: Resolved "Undefined name 'logger'" errors in core templates.

## 1.4.1
- Fix: Corrected relative import paths and prevented duplicate constructor generation during storage surgery.
- Fix: Ensured idempotent feature registration in `injection_container.dart`.

## 1.4.0
- Feat: Added modular storage command suite with Drift and Shared Preferences support.
- Feat: Implemented dynamic presentation folder naming based on state management selection.
- Feat: Added `permission` command and `test` command for cross-platform and QA scaffolding.

## 1.3.0
- Feat: Enhanced `init` to generate fully wired production core infrastructure.
- Feat: Added canonical implementations for `SecureStorage` and `NetworkInfo`.
- Feat: Automated dependency injection for all core singletons.

## 1.2.1
- UX: Added interactive conflict manager for file scaffolding.

## 1.2.0
- Feat: Populated `core/` with Router, Theme, Storage, and Networking boilerplate.
- Feat: Added `docs` command for terminal-based architectural reference.

## 1.1.0
- Feat: Added state management selection for BLoC and Riverpod.
- Refactor: Migrated to native Dart Analyzer Plugin system.

## 1.0.0
- Initial release with Absolute Rule Architecture scaffolding and enforcement.
