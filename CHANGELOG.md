# Changelog

## 1.4.0
- **Modular Storage Engine**: New `storage` command with `storage init` (Drift/SharedPrefs) and `storage feature` (retroactive injection).
- **Surgical Injection**: Intelligent code patching for existing features—injects fields, constructors, and imports without overwriting custom logic.
- **Dynamic Presentation Folders**: Automatically uses `bloc/` or `providers/` subdirectories based on state management selection.
- **Automated Feature Wiring**: Seamless auto-registration of features in `injection_container.dart` and `AppDatabase`.
- **QA Mirroring**: Feature test generation now automatically mirrors the dynamic folder structure.
- **Infrastructure Update**: Updated analyzer stack to support version 13.0.0.

## 1.3.1
- **Magic Permission Command**: Added `permission` command for automated cross-platform permission configuration.
- **Multi-Platform Patching**: Automatically updates AndroidManifest.xml, Info.plist, and PermissionService (Dart).
- **Interactive Menu**: Added interactive selection for common permissions (Camera, Location, etc.).
- **Improved Scaffolding**: Refined `init` to ensure zero-setup internet connectivity on all platforms.
- **Integrated QA**: New `test` command for Live API and Unit test scaffolding with `mocktail`.

## 1.3.0
- **Zero-Latency Engine**: `init` command now generates a fully wired, production-ready core.
- **Implemented Infrastructure**: Added canonical implementations for `SecureStorage` (Secure Storage) and `NetworkInfo` (Connectivity).
- **Auto-DI Registration**: `injection_container.dart` now automatically registers all core singletons.
- **Wired Networking**: `ApiClient` is pre-configured with `AppConfig`, `AuthInterceptor`, and `LoggingInterceptor`.
- **Productivity Utilities**: Added standard extensions (Context, String) and `ValidatorUtils`.
- **Reference UI**: Added `PrimaryButton` and `AppScaffold` shared widgets.

## 1.2.1
- **Interactive Conflict Manager**: Added a smart prompt (Yes/No/Always/Skip-All) when files already exist during scaffolding.
- **Improved UX**: Reduced repetitive prompts during bulk operations like `init`.

## 1.2.0
- **Production-Ready Scaffolding**: `init` command now populates `core/` with canonical boilerplate for Router, Theme, Storage, and Networking.
- **Dynamic Docs Command**: Added `docs` command for instant terminal access to Absolute Rules and Project Skeleton.
- **Safety Guards**: Added `--force` flag to `init` and `feature` commands to prevent accidental file overwrites.
- **Data Source Reorganization**: Transitioned to mandatory `local_data_sources` and `remote_data_sources` subdirectories.

## 1.1.0
- Added support for BLoC and Riverpod state management selection via `--state` flag.
- Migrated to native Dart Analyzer Plugin system.
- Improved dependency management with flexible version ranges.
- Added `build.yaml` generation for reliable Freezed output.

## 1.0.0
- Initial release with Absolute Rule Architecture scaffolding and enforcement.
