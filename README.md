# rocket_pocket

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Test Coverage

Run filtered unit-test coverage in one command:

```bash
bash scripts/coverage.sh
```

This command will:

- run `flutter test --coverage`
- create `coverage/lcov.cleaned.info` with generated files removed
- print overall filtered coverage percentage

To also generate an HTML report (requires `lcov`/`genhtml`):

```bash
bash scripts/coverage.sh --html
```
