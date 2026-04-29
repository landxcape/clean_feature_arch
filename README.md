# Clean Feature Architecture (Absolute Rule)

CLI and analyzer for scaffolding and enforcing the **Absolute Rule Architecture** in Flutter projects.

## Installation

Add the toolkit to your `dev_dependencies`:

```bash
dart pub add -d clean_feature_arch
```

---

## CLI Features

Run the toolkit using `dart run clean_feature_arch`:

### 1. Initializing a Project
Scaffolds a production-ready core (Router, Theme, Storage, Networking) and the **Absolute Resource Suite** (Assets, Localization, Context Extensions).
```bash
# Default (Pure Dart)
dart run clean_feature_arch init

# With specific state management
dart run clean_feature_arch init --state bloc
dart run clean_feature_arch init --state riverpod
```

### 2. Generating a Feature
Creates feature layers (`domain`, `data`, `presentation`) with canonical templates.
```bash
dart run clean_feature_arch feature <name> --state [bloc|riverpod|none] --storage [drift|shared|none]
```

### 3. Modular Storage Management
Initialize storage engines and surgically inject them into features.
```bash
# 1. Initialize a global engine (Drift or Shared Preferences)
dart run clean_feature_arch storage init

# 2. Add storage to an existing feature (Surgical injection)
dart run clean_feature_arch storage feature <name> --type [drift|shared]
```

### 4. Adding Permissions
Configure system permissions across all platforms and the Dart service:
```bash
# Open interactive menu
dart run clean_feature_arch permission

# Direct add
dart run clean_feature_arch permission camera
```

### 5. CI/CD Scaffolding
Generate automation workflows for your project:
```bash
# Support for GitHub Actions and GitLab CI
dart run clean_feature_arch ci
```

### 6. Test Scaffolding
Initialize professional test infrastructure:
```bash
# Scaffolds unit tests for core infrastructure (e.g., ApiClient)
dart run clean_feature_arch test --init

# Scaffolds full test suite for a feature (Integration + Unit)
dart run clean_feature_arch test <feature_name>
```

### 7. Accessing Documentation
```bash
# Instant terminal references for Absolute Rules and Project Skeleton
dart run clean_feature_arch docs rules
dart run clean_feature_arch docs skeleton
```

### Overwriting Files
Use the `-f` or `--force` flag to bypass the interactive conflict manager:
```bash
dart run clean_feature_arch init --force
```

---

## Static Analysis (Enforcer)

A native analyzer plugin enforces architectural boundaries directly within `dart analyze` and your IDE.

### Enabling the Enforcer
Add to `analysis_options.yaml`:

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

Detailed guides are available in the `doc/` directory or via the `docs` command:

- [**Core Architecture Guide**](https://github.com/landxcape/clean_feature_arch/blob/main/doc/flutter_architecture.md)
- [**State Management Guides**](https://github.com/landxcape/clean_feature_arch/tree/main/doc/state_management)

## License
Distributed under the MIT License. See [LICENSE](LICENSE) for details.
