# Clean Feature Architecture (Absolute Rule)

A Flutter development toolkit for scaffolding and enforcing the Absolute Rule Architecture. This package provides a CLI for feature generation and a custom linter for architectural verification.

## Absolute Rule Architecture

The Absolute Rule is a feature-first Clean Architecture pattern designed for large-scale production applications.

### Core Principles
- **Feature Isolation**: Features are self-contained and do not import internal classes from other features.
- **Layer Separation**: 
    - `domain`: Contains business logic and entities. No dependencies on `data` or `presentation`.
    - `data`: Implements repository contracts and manages data sources and models.
    - `presentation`: Contains UI components and state management.
- **Model Standard**: Data models (`Request`, `Response`, `Local`) and domain entities use `sealed class` with `@freezed` for type safety and exhaustive pattern matching.
- **Directory Hierarchy**: Models are organized into `requests/`, `responses/`, and `local/` subdirectories within the data layer.

## Functionality

### Scaffolder (CLI)
Generates feature structures with architectural boilerplate.

```bash
# Initialize core architecture (AppError, InjectionContainer, ApiClient, etc.)
dart run clean_feature_arch init

# Generate a new feature
dart run clean_feature_arch feature <name>
```

### Enforcer (Linter)
A `custom_lint` plugin providing architectural verification.

- **Feature Isolation**: Prevents cross-feature internal imports.
- **Layer Boundaries**: Prevents the `domain` layer from depending on other layers.
- **Model Requirements**: Ensures all `@freezed` models use the `sealed` keyword.
- **Folder Structure**: Validates that models are located in specified subdirectories.

## Installation

Add the package to `dev_dependencies`:

```yaml
dev_dependencies:
  clean_feature_arch: ^1.0.0
  custom_lint: ^0.6.0
```

Enable the plugin in `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
```

## Usage

### Scaffolding a Feature
The command `dart run clean_feature_arch feature auth` generates the following structure:

```
lib/features/auth/
├── data/
│   ├── datasources/
│   ├── models/
│   │   ├── local/
│   │   ├── requests/
│   │   └── responses/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── screens/
    └── state/
```

### Initializing a Project
The `init` command bootstraps the `lib/core` directory with required utilities and configures `analysis_options.yaml`.

## License
Distributed under the MIT License. See [LICENSE](LICENSE) for details.
