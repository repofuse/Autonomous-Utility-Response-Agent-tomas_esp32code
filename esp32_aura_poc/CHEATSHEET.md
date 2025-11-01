# Aura ESP32 Hackathon Cheatsheet

Hardware
- Board: ESP32-WROVER-E (ESP32 Arduino core)
- LED: on-board LED (default LED_BUILTIN=33 on many ESP32-CAM)
- Button: built-in BOOT button on GPIO0
  - Note: Don’t hold BOOT during reset, or the board enters download mode
  - Change pins via flags: -DLED_BUILTIN=xx, -DBUTTON_PIN=xx

WiFi config (in sketch)
- WIFI_SSID, WIFI_PASSWORD

Endpoints (real backend)
- Base: https://aura-backend-5hi0.onrender.com
- GET /health
- GET /grid-status
- POST /simulate-stress-event
- POST /report-savings

Button gestures → endpoint mapping
- Single click → POST /simulate-stress-event
  - LED: 1 quick blink on success; 3 quick blinks on failure
- Double click → POST /report-savings
  - LED: 2 quick blinks on success; 3 quick blinks on failure
- Triple click → GET /grid-status
  - LED steady reflects status: ON=STRESSED, OFF=normal; plus 2 quick ack blinks
- Long press (~1.2s) → GET /health
  - LED: 1 long blink on success; 3 quick blinks on failure
- Very long press (~3s) → Toggle Hardware Test Mode
  - LED: long blink entering, short blink exiting; in Test Mode the LED blinks at 250ms and the device prints button state, while network actions are paused

Background polling
- Every 10s: GET /grid-status
- If STRESSED: POST /report-savings once per stress event
- LED steady ON while stressed; OFF when normal

Demo without backend (no login)
- Enable echo mode:
  - In code: set `#define USE_DEMO_ECHO 1`
  - Or build flags: `-DUSE_DEMO_ECHO=1`
- Set the capture URL:
  - BACKEND_BASE (echo mode) is set to your request bin: `https://webhook.site/e390cf37-7ff1-4e11-813b-0b9a2e7480c7`
  - Open that URL in your browser to see requests live
- Behavior in echo mode:
  - All GETs/POSTs go to your webhook URL with endpoint paths appended (e.g., `/simulate-stress-event`, `/report-savings`)
  - Grid status is simulated locally:
    - Single click (simulate-stress) sets STRESSED
    - After auto report, status returns to normal
  - LED patterns and button mappings remain the same

Quick steps (real backend)
1) Set WiFi credentials
2) Flash sketch; open Serial Monitor at 115200
3) Single click: trigger stress; wait a few seconds; LED steady ON while stressed
4) Auto report occurs; when normal, LED OFF
5) Triple click: GET grid-status and see LED reflect state
6) Double click: manual report
7) Long press: health check
8) Very long press: toggle Test Mode

Quick steps (echo mode)
1) Build with `-DUSE_DEMO_ECHO=1` (or edit sketch)
2) Flash, open Serial Monitor
3) Use button gestures; watch httpbin responses and LED patterns

Troubleshooting
- If HTTPS fails: we use setInsecure() for demo; network time shouldn’t block
- If button seems unresponsive: ensure proper pull-up wiring and debounce (already in code)
- If LED not visible: some boards use different LED pins; adjust LED_BUILTIN if needed
