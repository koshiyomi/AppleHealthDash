# iOS Health Bridge App (Sample)

This sample SwiftUI app demonstrates **Option 2** from the main README: using your own HealthKit-enabled iOS app to gather metrics with user consent and forward them to a private API that your CLI can read.

> ⚠️ This is a starting point, not production-ready code. Add error handling, background refresh policies, and compliance reviews before shipping.

## Features
- Requests HealthKit authorization for a small, auditable set of metrics (steps, resting heart rate, sleep duration).
- Fetches the most recent values on demand.
- Posts redacted, aggregated metrics to a private endpoint you control using a short-lived bearer token (no tokens are persisted).
- Keeps Health data on-device until you explicitly send it.

## Project structure
- `HealthBridgeApp.swift`: SwiftUI app entry point that initializes the controller.
- `HealthDataController.swift`: Handles HealthKit authorization, reads metrics, and uploads them to your API.

You can drop these files into a new Xcode project (iOS 16+ target, SwiftUI lifecycle) and wire the UI of your choice.

## Setup steps
1. In Xcode, create a new **App** project using SwiftUI.
2. Add the two sample source files from this folder.
3. In your project settings:
   - Enable the **HealthKit** capability.
   - Under **Signing & Capabilities → Background Modes**, enable `Background fetch` only if you plan to extend for periodic refresh (not included here).
4. Replace `YOUR_API_BASE_URL` with your HTTPS endpoint and ensure it requires your short-lived token.
5. Provide a UI for users to tap **Authorize** and **Send** (e.g., simple buttons calling `requestAuthorization()` and `sendMetrics()` on `HealthDataController`).
6. Provide the token at runtime (e.g., prompt the user or retrieve from a secure enclave/keychain); the sample expects it as a parameter when calling `sendMetrics(token:)`.

## Security guidance
- Request only the HealthKit types you actually need.
- Use short-lived API tokens and avoid persisting them; the sample keeps tokens in memory only.
- Prefer your own API over third-party relays; ensure the server enforces TLS and authentication.
- If you add background delivery, surface clear UX for users to pause/stop uploads.

## Mapping to the CLI
- The CLI can hit your API endpoint to retrieve the same metrics; ensure both sides agree on field names.
- Example payload sent by the app:
  ```json
  {
    "steps": 10420,
    "heart_rate_resting": 58,
    "sleep_duration_minutes": 430
  }
  ```
- Adjust the CLI `fetch_metrics` to GET from the same endpoint (using the same short-lived token) and display matching labels.

## Testing tips
- Test on a real device (HealthKit is limited in the simulator).
- Use Xcode’s **Debug → Simulate Location** and manual Health app entries to seed data.
- Monitor network requests via your API logs; avoid logging raw tokens or Health data in production builds.
