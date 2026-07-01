# Architecture

## Goals

- Separate **widgets (UI)** from **implementation (services)**.
- Validate features early via **Testdroid** before polishing production UI.
- Keep a single HTTP entry point (`ApiService`) for future REST/auth work.

## Service layer

```
UI / Testdroid  →  getIt<XxxService>()  →  XxxServiceImpl  →  plugins / API
```

### Rules

1. `lib/ui/` and `lib/testsuit/` must not import device plugins (camera, geolocator, sqflite, etc.) except through services.
2. Domain services must not perform raw HTTP; use `ApiService`.
3. Register all services in `lib/service_locator.dart`.
4. Services may expose `getTestSuit()` for Testdroid auto-discovery.

### Lifecycle

- `ZServiceCenter.init()` — async setup (DB open, TTS init).
- `ZServiceCenter.destroy()` — optional teardown.

## Testdroid

### Registration

On startup, `ZTestSuitRegistry.initialize()`:

1. Iterates registered services and adds any non-null `getTestSuit()`.
2. Adds **compound suites** listed in `setupServiceLocator()` (e.g. `PincodeTestSuit`, `MaintenanceTestSuit`).

### Test types

| Type | Example | Registration |
|------|---------|--------------|
| Service-owned | `DBTestSuit`, `LocationTestSuit` | `getTestSuit()` on impl |
| Compound | `PincodeTestSuit` (DB + TTS + map) | Manual in `service_locator.dart` |
| Maintenance | `ResetLocalTestState` | Manual compound suit |

### V1 feedback

Snackbar/toast only. Tests double as debug utilities.

### Reset local state

`MaintenanceTestSuit → Reset local state` clears local DB test data only — no server-side deletes.

## UI

Standard Flutter `StatelessWidget` / `StatefulWidget` with `Scaffold`. Navigation via `pushPage()` in `lib/core/navigation.dart`.

## Deep copy checklist

When copying this template for a new product:

1. Rename package and app id.
2. Trim unused services and test suites.
3. Add domain services and compound suits as needed.
4. Optionally gate Testdroid behind an easter egg in release builds.
