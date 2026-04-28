# Changelog

## 1.4.6
- Feat: Implemented standard asset directory structure for images, icons, fonts, and animations.
- Feat: Integrated `easy_localization` with centralized string management and JSON translation support.
- Feat: Added `BuildContext` extensions for theme access, media queries, and localization hooks.
- Feat: Added responsive scaling utilities for multi-dimension UI consistency.
- Refactor: Standardized all generated imports to fully-qualified package URIs.

## 1.4.5
- Refactor: Optimized import style for improved analyzer performance.
- Fix: Corrected relative path resolution in nested feature structures.

## 1.4.4
- Feat: Implemented optional production error reporting via `LogReporter` interface.
- Feat: Added automatic stacktrace capture for error-level diagnostics.
- Refactor: Standardized build-mode log filtering for production environment safety.

## 1.4.3
- Refactor: Converted infrastructure errors to Freezed models for consistent diagnostics.
- Feat: Added generic API response wrapper and interface for standardized backend communication.
- Fix: Enhanced `ErrorHandler.guard` to support automatic backend error message extraction.

## 1.4.2
- Feat: Integrated professional logging and API monitoring packages.
- Style: Resolved package lints to achieve maximum quality score.

## 1.4.1
- Fix: Resolved import depth and constructor duplication bugs in feature scaffolding.
- Chore: Updated dependency constraints for latest analyzer compatibility.

## 1.4.0
- Feat: Added modular storage command suite with support for Drift and Shared Preferences.
- Feat: Implemented surgical code patching for non-destructive existing feature upgrades.
- Feat: Added dynamic directory naming based on state management selection.
- Feat: Added `permission` command and `test` command for cross-platform and QA scaffolding.

## 1.3.0
- Feat: Enhanced `init` to generate fully wired production core infrastructure.
- Feat: Added canonical implementations for `SecureStorage` and `NetworkInfo`.
- Feat: Automated DI registration for all core singletons.
- Feat: Pre-configured `ApiClient` with interceptors and flavor support.

## 1.2.1
- UX: Added interactive conflict manager (Yes/No/Always/Skip-All) for scaffolding.

## 1.2.0
- Feat: Populated `core/` with Router, Theme, Storage, and Networking boilerplate.
- Feat: Added `docs` command for terminal-based architectural reference.

## 1.1.0
- Feat: Added state management selection for BLoC and Riverpod.
- Refactor: Migrated to native Dart Analyzer Plugin system.

## 1.0.0
- Initial release with Absolute Rule Architecture scaffolding and enforcement.
