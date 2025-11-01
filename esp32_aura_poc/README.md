# Aura Protocol ESP32 POC

Minimal proof-of-concept to connect an ESP32-WROVER-E to the Aura Protocol mock backend.

## What it does
- Connects to your WiFi
- Polls `GET /grid-status` every 10s
- If status becomes `STRESSED`, posts a report to `POST /report-savings` with a demo savings value
- Lights the onboard LED while stressed

## Files
- `esp32_aura_poc.ino` — Arduino sketch

## Requirements
- Arduino IDE (or PlatformIO)
- Board: `ESP32 Wrover Module` (or your ESP32-CAM/WROVER-E variant)
- Library dependencies: (bundled with ESP32 Arduino core)
  - `WiFi` (ESP32)
  - `WiFiClientSecure`
  - `HTTPClient`
- Hardware: built-in BOOT button (GPIO0) and built-in LED (default GPIO33 on many ESP32-CAM)

## Quick start (Arduino IDE)
1. Install ESP32 board support (Boards Manager → search `esp32` by Espressif)
2. Open `esp32_aura_poc.ino`
3. Edit the top of the file:
   - `WIFI_SSID` and `WIFI_PASSWORD`
   - Optionally `DEVICE_ADDRESS` and `SAVINGS_WATTS`
4. Tools → Board → select your ESP32 board (e.g., ESP32 Wrover Module)
5. Tools → Upload Speed: 921600 (optional)
6. Compile and Upload
7. Open Serial Monitor at 115200 baud

## Backend and Demo Modes
- Real backend (default when `USE_DEMO_ECHO=0`):
  - Base URL: `https://aura-backend-5hi0.onrender.com`
- Echo/demo capture mode (when `USE_DEMO_ECHO=1`):
  - Base URL: `https://webhook.site/e390cf37-7ff1-4e11-813b-0b9a2e7480c7`
  - Open this URL in a browser to see live requests from the device
- Endpoints used (same paths in both modes):
  - `GET /health`
  - `GET /grid-status`
  - `POST /simulate-stress-event`
  - `POST /report-savings` with JSON body `{ "deviceAddress": "...", "savings": 50 }`

Note: The sketch uses `client.setInsecure()` (disables TLS cert validation) for hackathon speed. For production, provide the server root certificate and validate it.

## Demo flow

### Button behaviors (built-in BOOT button only)
- Single click: POST /simulate-stress-event (triggers a stress window or sets local STRESSED in echo mode)
- Double click: POST /report-savings immediately (manual savings report)
- Triple click: GET /grid-status (LED updates to show STRESSED=ON, normal=OFF; plus 2 short ack blinks)
- Long press (~1.2s): GET /health (1 long blink on success, 3 quick blinks on failure)
- Very long press (~3s): Toggle Hardware Test Mode (blinks LED, prints button state, pauses network actions)

Note: Do not hold BOOT while resetting or powering up, or the board will enter download mode. A 2s grace period after boot prevents accidental actions.

### Steps
- Start with the server in normal state.
- Use the built-in BOOT button for all actions.
- Optionally, from a laptop, trigger stress:
  ```bash
  curl -X POST https://aura-backend-5hi0.onrender.com/simulate-stress-event
  ```
- The ESP32 will detect `STRESSED` during its next poll, turn LED on, and call `POST /report-savings`.
- After reporting, when the grid returns to normal, LED turns off and device resets its report flag.

## Troubleshooting
- If HTTPS fails, ensure the device has correct time (ESP32 uses SNTP after WiFi connect). We bypass TLS with `setInsecure()`, so cert time shouldn’t block the demo.
- If WiFi won’t connect, double-check SSID/password and 2.4GHz availability.
- If responses are unexpected, open Serial Monitor to see raw payloads.

## Optional improvements (post-hackathon)
- Parse JSON properly (ArduinoJson) and track transaction hash
- Add exponential backoff and persistent state across reboots
- Include the backend’s TLS root certificate and enable validation
- Add device claim/registration endpoint with a real device key
