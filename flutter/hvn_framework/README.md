# hvn_framework — Flutter App Template

A pattern-oriented Flutter template separating **UI**, **services**, and **Testdroid** (in-app test harness).

## Architecture

### Service layer

- **Interfaces** live in `lib/service/` (e.g. `DBService`, `TTSService`, `ApiService`).
- **Implementations** live in `lib/service/impl/`.
- **Wiring** is centralized in `lib/service_locator.dart` using [`get_it`](https://pub.dev/packages/get_it).
- UI and Testdroid access services via `getIt<MyService>()` — never import plugins directly from `ui/` or `testsuit/`.
- Domain services call **`ApiService`** for HTTP (stub included for future REST work).

### Testdroid

- **`ZTest`** — one executable action (snackbar, navigation, service call).
- **`ZTestSuit`** — groups related tests.
- **Auto-discovery** — services override `getTestSuit()` on `ZServiceCenter`.
- **Compound suites** — cross-cutting tests (e.g. `PincodeTestSuit`) registered manually in `setupServiceLocator()`.
- **`TestdroidPage`** — generic grid UI; tests may open simple scratch screens.

### Adding a feature

1. Define `XxxService` + `XxxServiceImpl`.
2. Register in `service_locator.dart` and add to the `services` list.
3. Optionally implement `getTestSuit()` on the service impl.
4. Build production UI in `lib/ui/` calling `getIt<XxxService>()`.

## Run

```bash
flutter pub get
flutter run
```

Open **Dashboard → Testdroid Dashboard** to run test suites.

## Key files

| File | Role |
|------|------|
| `lib/service_locator.dart` | Service registration and Testdroid init |
| `lib/service/z_service_center.dart` | Service base type |
| `lib/testdroid/z_testsuit_registry.dart` | Test suite catalog |
| `lib/ui/testdroid.dart` | Testdroid shell UI |

See [ARCHITECTURE.md](ARCHITECTURE.md) for full pattern notes.
