# ELI5: Demo with no-login request capture (webhook.site)

Goal: Demo the full flow without any logins or special backend.

Turn on echo mode
- Build with `-DUSE_DEMO_ECHO=1` (or edit the sketch to set `#define USE_DEMO_ECHO 1`)
- BACKEND_BASE in echo mode points to your capture URL:
  - `https://webhook.site/e390cf37-7ff1-4e11-813b-0b9a2e7480c7`
- Flash and open Serial Monitor at 115200
- Open that URL in your browser; each device request appears in the list
- You will use ONLY the built-in BOOT button and built-in LED

What echo mode does
- All requests go to your unique webhook URL (visible in your browser)
- The device simulates the grid status locally:
  - Single click sets STRESSED internally
  - After the device reports once, it goes back to normal
- LED + button behavior is the same as the real backend demo

Demo steps (60 seconds)
1) Health check (hold ~1.2s)
   - LED 1 long blink, Serial shows a 200 OK from httpbin
2) Trigger stress (single click)
   - LED quick blink, Serial shows a POST to /post
3) Verify status (triple click)
   - LED steady ON (we’re simulating STRESSED)
4) Auto report (wait up to 10s) or double click to report now
   - Serial shows POST /post
5) After reporting, status returns to normal
   - LED steady OFF

Why this is useful
- It proves the device, the button logic, the LED signals, and the HTTP stack—all without a custom backend.
