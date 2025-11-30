# Apple Health Dashboard (Local CLI Skeleton)

This repository provides a minimal, privacy-conscious CLI scaffold for building a local Apple Health data dashboard. The design intentionally avoids storing long-lived credentials and keeps sensitive values out of configuration files.

## Data source assumptions
- Apple does not expose a direct public web API for Health data. Typical access patterns include exporting Health data (via the iOS Health app) or using a first-party app you control that exposes an authorized API endpoint.
- Integrate only with data sources you own and that comply with Apple’s terms and your local privacy requirements.

## Credential handling philosophy
- **No persistent secrets by default.** The CLI expects a short-lived session token provided at runtime (environment variable or interactive prompt) and does not write it to disk.
- **Optional OS keychain.** If you want automatic re-entry without storing plaintext, consider adding a keychain-based adapter (not included here) rather than writing secrets to a file.
 - **Config files are for non-sensitive settings only.** Keep refresh intervals, metric selections, and display options in config. Avoid placing API keys or tokens in JSON or any plaintext files.

## Quick start
1. Copy the sample configuration:
   ```bash
   cp config.example.json config.json
   ```
2. Provide a session token each run (choose one):
   - Set an environment variable before execution:
     ```bash
     export APPLE_HEALTH_SESSION_TOKEN="<short-lived-token>"
     ```
   - Or allow the CLI to prompt for a token interactively at startup.
3. Run once to verify output:
   ```bash
   python cli.py --once
   ```
4. Run continuously with a 5-minute refresh (customizable in config):
   ```bash
   python cli.py
   ```

## Configuration
`config.json` (based on `config.example.json`) supports:
- `refresh_minutes`: Interval between fetches (default 5).
- `metrics`: A list of metrics to display; each metric may specify a `name` and a user-facing `label`.

Example:
```json
{
  "refresh_minutes": 5,
  "metrics": [
    { "name": "steps", "label": "Steps" },
    { "name": "heart_rate_resting", "label": "Resting HR" },
    { "name": "sleep_duration", "label": "Sleep (hrs)" }
  ]
}
```

## Security recommendations
- Prefer **short-lived tokens** and require login each session; avoid storing passwords or refresh tokens on disk.
- If you must persist secrets, use an **OS keychain or a secrets manager** instead of plaintext files.
- When debugging, avoid logging raw tokens; the CLI redacts token output.
- Treat exported Health data files as sensitive and store them in encrypted locations if retained.

## Extending the skeleton
- Replace the placeholder `fetch_metrics` implementation in `cli.py` with calls to your trusted data source.
- If you add keychain support, encapsulate it behind a dedicated module so the default remains stateless.
- Consider adding unit tests that mock the data source and verify no secrets are written to disk.

## Disclaimer
This scaffold does not connect to Apple Health directly. You are responsible for integrating with an authorized data source and for complying with all applicable terms and privacy requirements.
