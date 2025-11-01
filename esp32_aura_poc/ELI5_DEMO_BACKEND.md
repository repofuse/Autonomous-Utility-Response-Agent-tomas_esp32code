# ELI5: Demo with real backend (Aura mock server)

Goal: Show an end-to-end flow against https://aura-backend-5hi0.onrender.com using one button.

Before you start
- Make sure the board is flashed and connected to WiFi (see ELI5_SETUP.md)
- The sketch already points to the real backend by default
- You will use ONLY the built-in BOOT button and built-in LED

What the LED means
- Steady ON = grid is STRESSED
- Steady OFF = grid is normal
- 1 quick blink = we sent a trigger
- 2 quick blinks = we sent a report
- 3 quick blinks = error
- 1 long blink = health is OK

Button cheats
- Single click → POST /simulate-stress-event (start stress)
- Double click → POST /report-savings (manual report)
- Triple click → GET /grid-status (LED updates to match)
- Long press (~1.2s) → GET /health
- Very long press (~3s) → Toggle Hardware Test Mode (blinks fast, pauses network)

60-second flow
1) Check health (hold button ~1.2s)
   - LED 1 long blink = healthy
2) Trigger stress (single click)
   - LED quick blink to acknowledge
3) Verify status (triple click)
   - LED becomes steady ON when stressed
4) Auto report happens automatically on the next poll (up to ~10s)
   - Or double click to report immediately
5) When stress ends, LED goes OFF
   - Triple click again if you want to check status

That’s it! One button, one LED, real blockchain interaction behind the scenes.
