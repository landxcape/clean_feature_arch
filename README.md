# Clean Feature Architecture (Absolute Rule)

CLI and analyzer for scaffolding and enforcing the **Absolute Rule Architecture** in Flutter projects.

## Installation

Add the toolkit to your `dev_dependencies`:

```bash
dart pub add -d clean_feature_arch
```

---

## CLI Features (Scaffolder)

Run the toolkit using `dart run clean_feature_arch`:

### Initializing a Project
Scaffolds a production-ready core (Router, Theme, Storage, Networking) and configures baseline dependencies.
```bash
# Default (Pure Dart)
dart run clean_feature_arch init

# With BLoC or Riverpod
dart run clean_feature_arch init --state bloc
dart run clean_feature_arch init --state riverpod
```

### Generating a Feature
Creates feature layers (`domain`, `data`, `presentation`) with canonical templates.
```bash
# Default
dart run clean_feature_arch feature <name>

# With specific state management
dart run clean_feature_arch feature <name> --state bloc
dart run clean_feature_arch feature <name> --state riverpod
```

### Adding Permissions
Configure system permissions across all platforms and the Dart service:
```bash
# Open interactive menu
dart run clean_feature_arch permission

# Direct add
dart run clean_feature_arch permission camera
dart run clean_feature_arch permission location
```

### Accessing Documentation
Access architectural references directly from the terminal or open full guides in your browser:
```bash
# Open interactive menu
dart run clean_feature_arch docs

# Instant terminal references
dart run clean_feature_arch docs rules
dart run clean_feature_arch docs skeleton
```

### Overwriting Files
Use the `-f` or `--force` flag to overwrite existing files:
```bash
dart run clean_feature_arch init --force
```

---

## Static Analysis (Enforcer)

A native analyzer plugin enforces architectural boundaries directly within `dart analyze` and your IDE.

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

Detailed guides are available in the `doc/` directory or via the `docs` command:

- [**Core Architecture Guide**](https://github.com/landxcape/clean_feature_arch/blob/main/doc/flutter_architecture.md)
- [**State Management: Common Rules**](https://github.com/landxcape/clean_feature_arch/blob/main/doc/state_management/common.md)
- [**State Management: BLoC**](https://github.com/landxcape/clean_feature_arch/blob/main/doc/state_management/bloc.md)
- [**State Management: Riverpod**](https://github.com/landxcape/clean_feature_arch/blob/main/doc/state_management/riverpod.md)

## License
Distributed under the MIT License. See [LICENSE](LICENSE) for details.
