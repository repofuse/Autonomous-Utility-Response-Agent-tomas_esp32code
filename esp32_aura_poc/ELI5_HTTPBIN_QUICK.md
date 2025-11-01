# ELI5: Demo Everything with webhook.site (No Login)

What is webhook.site?
- A public request capture site that shows every GET/POST your device sends to your unique URL. Perfect to prove your device makes real HTTPS requests you can see in a browser.

Step 1 — Enable echo mode in the sketch
- Open `esp32_aura_poc/esp32_aura_poc.ino` in Arduino IDE.
- At the top, set:
  ```
  #ifndef USE_DEMO_ECHO
  #define USE_DEMO_ECHO 1   // turn on echo mode
  #endif
  ```
  (Alternatively, compile with a flag so you don’t edit code: `-DUSE_DEMO_ECHO=1`.)
- Upload to the ESP32 and open Serial Monitor at 115200.

What echo mode does automatically
- Base URL becomes your capture URL:
  - `https://webhook.site/e390cf37-7ff1-4e11-813b-0b9a2e7480c7`
- Endpoints are sent to that base with the same paths (you’ll see them listed in your browser):
  - GET `/health`
  - GET `/grid-status`
  - POST `/simulate-stress-event`
  - POST `/report-savings`
- Grid status is simulated locally so the demo still “acts” like your backend:
  - Single click (stress) sets STRESSED internally
  - Polling shows STRESSED and turns LED steady ON
  - Auto report runs once per stress event, then the device returns to normal (LED OFF)

Hardware used
- Built-in BOOT button (GPIO0) for all input gestures
- Built-in LED for all feedback (default `LED_BUILTIN=33` on many ESP32-CAM; override with `-DLED_BUILTIN=xx` if needed)
- Safety: Do NOT hold BOOT during reset/power-up (enters download mode). Code ignores button for 2 seconds after boot to avoid accidental actions.

Step 2 — Use one button for the whole demo
- Gestures and LED patterns:
  - Single click → POST `/simulate-stress-event`
    - LED: 1 quick blink on success; 3 quick blinks on failure
    - Serial: logs POST to your webhook URL; in the browser list you’ll see `/simulate-stress-event`
    - Internally sets STRESSED; LED steady ON after next poll
  - Double click → POST `/report-savings` (manual report)
    - LED: 2 quick blinks on success; 3 quick on failure
    - Serial: logs POST to your webhook URL; browser shows the JSON body
  - Triple click → GET `/grid-status`
    - LED: 2 quick blinks to acknowledge; then steady ON if STRESSED, OFF if normal
    - Serial: logs GET to your webhook URL; browser shows the request
  - Long press (~1.2s) → GET `/health`
    - LED: 1 long blink on success; 3 quick on failure
    - Serial: logs GET to your webhook URL; browser shows the request
  - Very long press (~3s) → Toggle Hardware Test Mode
    - LED blinks at 250ms; Serial prints button state every 500ms; network paused
    - Long hold again to exit

Step 3 — 60-second narration (use this on stage)
1) “We’re using httpbin.org, a public echo service—no account needed.”
2) Long press: “Health check.” LED does one long blink; Serial shows status 200.
3) Single click: “Trigger stress.” LED quick blink; Serial shows a POST to `/post`. Device now simulates STRESSED.
4) Triple click: “Read grid status.” LED 2 quick blinks, then steady ON (STRESSED).
5) Auto report (wait up to ~10s) or double click to report immediately. Serial shows a POST to `/post` with JSON.
6) After reporting, the device returns to normal. LED steady OFF. Triple click again if you want to confirm.
7) Very long press: “Hardware Test Mode.” LED blinks quickly; Serial shows button state. Hold again to exit.

How to confirm it’s working
- Serial Monitor prints:
  - `➡️ GET https://httpbin.org/get` or `➡️ POST https://httpbin.org/post`
  - `⬅️ 200` followed by a JSON echo
- For POSTs, your payload appears in the echoed JSON (`json` or `data`).

Common questions
- Do I need an account? No.
- Is it HTTPS? Yes. The sketch uses `WiFiClientSecure` (with `setInsecure()` for demo speed).
- What if LED or BOOT aren’t correct on my board? Run `tools/pin_finder.ino` to discover pins, then build with flags:
  - `-DLED_BUILTIN=xx`
  - `-DBUTTON_PIN=xx`

Quick fallback back to real backend
- Set `#define USE_DEMO_ECHO 0` (or remove the build flag), upload, and use the same gestures. The code will hit your real backend instead of httpbin.
