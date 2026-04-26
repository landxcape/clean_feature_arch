# Changelog

## 1.4.4
- Feat: Implement optional production error reporting via `LogReporter` interface.
- Feat: Enforce mandatory stacktrace capture for error-level diagnostics.
- Refactor: Standardize environment-aware log filtering for production safety.

## 1.4.3
- Fix: Corrected relative import paths in BLoC and LocalDataSource templates.
- Fix: Prevented duplicate constructor generation during retroactive storage surgery.
- Fix: Ensured idempotent feature registration in `injection_container.dart`.
- Chore: Updated analyzer dependency constraints for version 13.0.0 compatibility.
- Style: Resolved all remaining lints to ensure perfect package analysis scores.

## 1.4.2
- Feat: Integrated `logger` and `pretty_dio_logger` for professional, production-grade logging.
- Feat: Added debug-only log filtering to prevent sensitive data leaks in release mode.
- Fix: Resolved "Undefined name 'logger'" errors in `ErrorHandler` and `main.dart`.
- Fix: Perfected analyzer scores with final template lint cleanup.

## 1.4.1
- Fix: Corrected relative import paths in BLoC and LocalDataSource templates.
- Fix: Prevented duplicate constructor generation during retroactive storage surgery.
- Fix: Ensured idempotent feature registration in `injection_container.dart`.
- Chore: Updated analyzer dependency constraints for version 13.0.0 compatibility.
- Style: Resolved all remaining lints to ensure perfect package analysis scores.

## 1.4.0
- Feat: Added modular storage system via `storage init` and `storage feature` commands.
- Feat: Implemented surgical code patching for non-destructive feature upgrades.
- Feat: Implemented dynamic presentation folder naming (`bloc/`, `providers/`) based on state management.
- Feat: Added automated feature wiring in `injection_container.dart` and `AppDatabase`.
- Feat: Updated test generation to mirror dynamic project structures.

## 1.3.1
- Feat: Added `permission` command for automated cross-platform configuration.
- Feat: Implemented surgical patching for AndroidManifest.xml and Info.plist.
- Feat: Added interactive permission selection menu.
- Feat: Added `test` command for Live API and Unit test scaffolding.

## 1.3.0
- Feat: Enhanced `init` to generate fully wired production core infrastructure.
- Feat: Added canonical implementations for `SecureStorage` and `NetworkInfo`.
- Feat: Automated DI registration for all core singletons.
- Feat: Pre-configured `ApiClient` with interceptors and flavor support.
- Feat: Added standard utility extensions and shared widgets.

## 1.2.1
- UX: Added interactive conflict manager (Yes/No/Always/Skip-All) for scaffolding.

## 1.2.0
- Feat: Populated `core/` with Router, Theme, Storage, and Networking boilerplate.
- Feat: Added `docs` command for terminal-based architectural reference.
- Feat: Added `--force` flag for automated overrides.
- Refactor: Enforced mandatory `local_data_sources` and `remote_data_sources` structure.

## 1.1.0
- Feat: Added state management selection for BLoC and Riverpod.
- Refactor: Migrated to native Dart Analyzer Plugin system.
- Chore: Added `build.yaml` for Freezed compatibility.

## 1.0.0
- Initial release with Absolute Rule Architecture scaffolding and enforcement.
