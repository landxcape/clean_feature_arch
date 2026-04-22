# 1.2.1

- **Interactive Conflict Manager**: Added a smart prompt (`Yes/No/Always/Skip-All`) when files already exist during scaffolding.
- **Improved UX**: Reduced repetitive prompts during bulk operations like `init`.

# 1.2.0

- **Production-Ready Scaffolding**: `init` command now populates `core/` with canonical boilerplate for Router, Theme, Storage, and Networking.
- **Dynamic Docs Command**: Added `docs` command for instant terminal access to Absolute Rules and Project Skeleton, parsed directly from source guides.
- **Safety Guards**: Added `--force` flag to `init` and `feature` commands to prevent accidental file overwrites.
- **Data Source Reorganization**: Transitioned to mandatory `local_data_sources` and `remote_data_sources` subdirectories with enforced lint rules.
- **Enhanced State Management**: Added comprehensive support for BLoC and Riverpod state selection during both `init` and `feature` generation.
- **Project Bootstrapping**: `main.dart` and `app.dart` are now automatically wired to the generated core infrastructure.

# 1.1.0

- Added support for BLoC and Riverpod state management selection via `--state` flag.
- Migrated to native Dart Analyzer Plugin system.
- Improved dependency management with flexible version ranges.
- Added `build.yaml` generation for reliable Freezed output.
- Updated templates with professional technical documentation.

# 1.0.0

- Initial release with Absolute Rule Architecture scaffolding and enforcement.
