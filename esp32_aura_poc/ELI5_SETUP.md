# ELI5: Setup (ESP32 + WiFi + Upload)

Goal: Get the ESP32 connected to WiFi and ready to demo with a single button and single LED.

What you need
- ESP32 board (ESP32-WROVER-E or similar)
- USB cable
- 1 pushbutton
- 2 jumper wires
- A 2.4 GHz WiFi network (SSID + password)

Hardware (built-in only)
- Button: use the board’s BOOT button (GPIO0)
- LED: use the built-in onboard LED (default GPIO33 on many ESP32-CAM)
- Tip: Don’t hold BOOT while powering/resetting the board, or it enters download mode

Install Arduino IDE (if you don’t have it)
- Install Arduino IDE
- Boards Manager → search "esp32" by Espressif → Install
- Tools → Board → pick "ESP32 Wrover Module" (or your exact ESP32 board)

Open the project
- Open `esp32_aura_poc.ino`
- At the top, set:
  - WIFI_SSID = "your WiFi name"
  - WIFI_PASSWORD = "your WiFi password"
- Optional: override pins via build flags if your board uses different GPIOs:
  - `-DLED_BUILTIN=xx` (e.g., 2)
  - `-DBUTTON_PIN=xx` (default 0 = BOOT)

Flash it
- Select the right COM/Serial port
- Click Upload
- Open Serial Monitor at 115200 baud
- Wait for: "WiFi connected" and an IP address

You’re ready to demo!
- The one button controls everything
- The one LED tells you what’s happening
