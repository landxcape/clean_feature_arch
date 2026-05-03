# Clean Feature Architecture

CLI and analyzer for scaffolding and enforcing Clean Architecture in Flutter projects. Version 1.6.0 provides full support for modern Dart 3.x patterns and modular dependency injection.

## Installation

Add the toolkit to your `dev_dependencies`:

```bash
dart pub add -d clean_feature_arch
```

---

## Features

### Modern Dart 3.x Support
Scaffolded templates utilize modern Dart standards:
- **Switch Expressions**: Functional and exhaustive UI state rendering.
- **Record Destructuring**: Declarative application bootstrap and result handling.
- **Enhanced Enums**: Type-safe configuration and flavor management.
- **Sealed Classes**: Compiler-verified state and error handling.

### Modular Dependency Injection
Dependency injection follows a Modular Registry Pattern:
- **Core Module**: Centralized management for infrastructure, network, and storage.
- **Feature Modules**: Localized registration logic within each feature's `di/` directory.
- **Dispatcher**: A clean `injection_container.dart` that coordinates modular registries.

---

## CLI Usage

All commands are executed via `dart run clean_feature_arch`:

### 1. Project Initialization
Initializes the core architecture (Router, Theme, Storage, Networking) and shared resources (Assets, Localization, Context Extensions).
```bash
# Default
dart run clean_feature_arch init

# With BLoC or Riverpod
dart run clean_feature_arch init --state bloc
dart run clean_feature_arch init --state riverpod
```

### 2. Feature Generation
Creates the `domain`, `data`, and `presentation` layers for a new feature.
```bash
dart run clean_feature_arch feature <name> --state [bloc|riverpod|none] --storage [drift|shared|none]
```

### 3. Storage Management
Configure storage engines or integrate them into existing features.
```bash
# Initialize a global engine (Drift or Shared Preferences)
dart run clean_feature_arch storage init

# Add storage to an existing feature
dart run clean_feature_arch storage feature <name> --type [drift|shared]
```

### 4. Permission Configuration
Configure system permissions across all supported platforms.
```bash
# Interactive menu
dart run clean_feature_arch permission

# Direct command
dart run clean_feature_arch permission camera
```

### 5. CI/CD Scaffolding
Generate automated workflows for GitHub Actions or GitLab CI.
```bash
dart run clean_feature_arch ci
```

### 6. Test Scaffolding
Initialize unit and integration test infrastructure.
```bash
# Core infrastructure tests
dart run clean_feature_arch test --init

# Feature-specific test suite
dart run clean_feature_arch test <feature_name>
```

---

## Static Analysis

A native analyzer plugin enforces architectural boundaries and standards.

### Configuration
Add the plugin to your `analysis_options.yaml`:

```yaml
plugins:
  clean_feature_arch:
    diagnostics:
      absolute_rule_avoid_illegal_layer_imports: true
      absolute_rule_enforce_feature_isolation: true
      absolute_rule_enforce_model_folder_structure: true
      absolute_rule_prefer_sealed_freezed_models: true
      absolute_rule_enforce_data_source_folder_structure: true
```

---

## Documentation

Detailed technical guides:

- [**Core Architecture**](https://github.com/landxcape/clean_feature_arch/blob/main/doc/flutter_architecture.md)
- [**State Management**](https://github.com/landxcape/clean_feature_arch/tree/main/doc/state_management)

## License
Distributed under the MIT License. See [LICENSE](LICENSE) for details.
