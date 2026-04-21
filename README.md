# Clean Feature Architecture (Absolute Rule)

A Flutter development toolkit for scaffolding and enforcing the **Absolute Rule Architecture**. This package provides a CLI for feature generation and a native Dart analyzer plugin for architectural verification.

## Installation

### 1. Project Scaffolder (CLI)
To use the toolkit to bootstrap and generate features, add it to your `dev_dependencies`:

```bash
dart pub add -d clean_feature_arch
```

### 2. Project Enforcer (Linter)
The enforcer is included in the package. Once added to `dev_dependencies`, enable it in your `analysis_options.yaml` (see the **Enabling the Enforcer** section below).

---

## CLI Features (Scaffolder)

Run the toolkit using `dart run clean_feature_arch`:

### Initializing a Project
Bootstraps the `lib/core` directory with required utilities and configures baseline dependencies.
```bash
# Default (Pure Dart/No state manager)
dart run clean_feature_arch init

# With BLoC
dart run clean_feature_arch init --state bloc

# With Riverpod
dart run clean_feature_arch init --state riverpod
```

### Generating a Feature
Creates a standard feature directory structure (`domain`, `data`, `presentation`) with canonical templates.
```bash
# Default
dart run clean_feature_arch feature <name>

# With specific state management
dart run clean_feature_arch feature <name> --state bloc
dart run clean_feature_arch feature <name> --state riverpod
```

---

## Static Analysis (Enforcer)

The package includes a native Dart analyzer plugin that enforces architectural boundaries directly within `dart analyze` and your IDE.

### Enabling the Enforcer
Add the following to your `analysis_options.yaml`:

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

## Architecture Documentation

The detailed architectural specification and state management guides are available in the `doc/` directory:

-   [**Core Architecture Guide**](https://github.com/landxcape/clean_feature_arch/blob/main/doc/flutter_architecture.md): The full specification of the Absolute Rule.
-   [**State Management: Common Rules**](https://github.com/landxcape/clean_feature_arch/blob/main/doc/state_management/common.md): Rules that apply regardless of the tool.
-   [**State Management: BLoC**](https://github.com/landxcape/clean_feature_arch/blob/main/doc/state_management/bloc.md): Implementation guide for BLoC.
-   [**State Management: Riverpod**](https://github.com/landxcape/clean_feature_arch/blob/main/doc/state_management/riverpod.md): Implementation guide for Riverpod.

## License
Distributed under the MIT License. See [LICENSE](LICENSE) for details.
