# Clean Feature Architecture (Absolute Rule)

A Flutter development toolkit for scaffolding and enforcing the **Absolute Rule Architecture**. This package provides a CLI for feature generation and a native Dart analyzer plugin for architectural verification.

## Architecture Documentation

The detailed architectural specification and state management guides are available in the `doc/` directory:

-   [**Core Architecture Guide**](https://github.com/landxcape/clean_feature_arch/blob/main/doc/flutter_architecture.md): The full specification of the Absolute Rule.
-   [**State Management: Common Rules**](https://github.com/landxcape/clean_feature_arch/blob/main/doc/state_management/common.md): Rules that apply regardless of the tool.
-   [**State Management: BLoC**](https://github.com/landxcape/clean_feature_arch/blob/main/doc/state_management/bloc.md): Implementation guide for BLoC.
-   [**State Management: Riverpod**](https://github.com/landxcape/clean_feature_arch/blob/main/doc/state_management/riverpod.md): Implementation guide for Riverpod.

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
```

---

## CLI Features (Scaffolder)

### Initializing a Project
Bootstraps the `lib/core` directory with required utilities and configures baseline dependencies.
```bash
dart run clean_feature_arch init
```

### Generating a Feature
Creates a standard feature directory structure (`domain`, `data`, `presentation`) with canonical templates.
```bash
dart run clean_feature_arch feature <name>
```

## License
Distributed under the MIT License. See [LICENSE](LICENSE) for details.
