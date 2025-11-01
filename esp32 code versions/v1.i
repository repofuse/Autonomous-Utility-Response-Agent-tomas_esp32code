/*
  Aura Protocol ESP32 POC - Hackathon Minimal Client

  Target: ESP32-WROVER-E (Arduino framework)
  Purpose: Connect to WiFi, poll backend grid status, and when STRESSED, POST a savings report.

  Notes for rapid demo:
  - Uses HTTPS with certificate verification disabled (setInsecure). Good enough for a demo.
  - Avoids ArduinoJson to minimize dependencies; uses basic string checks.
  - LED indicator (LED_BUILTIN) toggles based on grid status.

  Backend endpoints (fixing malformed curl examples in spec):
  - GET  https://aura-backend-5hi0.onrender.com/health
  - GET  https://aura-backend-5hi0.onrender.com/grid-status
  - POST https://aura-backend-5hi0.onrender.com/simulate-stress-event
  - POST https://aura-backend-5hi0.onrender.com/report-savings
*/

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>

// ====== USER CONFIG ======
const char* WIFI_SSID     = "TatianaSF.com";     // <-- set your WiFi SSID
const char* WIFI_PASSWORD = "TatianaSF.com"; // <-- set your WiFi password

// Demo echo mode (no-login HTTP debugger via httpbin)
#ifndef USE_DEMO_ECHO
#define USE_DEMO_ECHO 0   // set to 1 or compile with -DUSE_DEMO_ECHO=1 to use httpbin.org
#endif

#if USE_DEMO_ECHO
const char* BACKEND_BASE = "https://httpbin.org";   // public echo service
#else
// Backend base URL
const char* BACKEND_BASE = "https://aura-backend-5hi0.onrender.com";
#endif

// Use a valid Ethereum address if possible; a placeholder works for demo
const char* DEVICE_ADDRESS = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb0"; // replace if you have a test device address

// Demo savings value to report when stressed
int SAVINGS_WATTS = 50; // tweak as needed

// Polling interval in milliseconds
unsigned long POLL_INTERVAL_MS = 10000; // 10 seconds

// LED pin (most ESP32 dev boards map LED_BUILTIN to 2). Adjust if needed.
#ifndef LED_BUILTIN
#define LED_BUILTIN 2
#endif

// Demo button pin: connect a momentary pushbutton between this pin and GND.
// Avoid boot-strapping pins (GPIO0). GPIO14 is safe on many boards; change if needed.
#ifndef BUTTON_PIN
#define BUTTON_PIN 14   // Override at compile time with: -DBUTTON_PIN=xx
#endif

const unsigned long DEBOUNCE_MS = 50;
const unsigned long CLICK_TIMEOUT_MS = 450;   // max gap between clicks for multi-click
const unsigned long LONGPRESS_MS = 1200;      // long press: GET /health
const unsigned long VERY_LONGPRESS_MS = 3000; // very long press: toggle Test Mode

// ====== INTERNAL STATE ======
unsigned long lastPollMs = 0;
bool reportedForThisStress = false;

// Button state
int lastButtonReading = HIGH;   // using INPUT_PULLUP, unpressed = HIGH
int stableButtonState = HIGH;
unsigned long lastDebounceTime = 0;

// Click tracking
bool buttonPressed = false;
unsigned long pressStartMs = 0;
unsigned long lastReleaseMs = 0;
int clickCount = 0;
bool waitingForSecondClick = false;

// Modes
bool testMode = false;   // Hardware Test Mode: blink LED and print button state; pause network actions
unsigned long lastBlinkMs = 0;
bool blinkState = false;

void connectWiFi() {
  Serial.printf("\nConnecting to WiFi: %s\n", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  uint8_t retries = 0;
  while (WiFi.status() != WL_CONNECTED && retries < 60) { // ~30s timeout
    delay(500);
    Serial.print(".");
    retries++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("\n✅ WiFi connected. IP: %s\n", WiFi.localIP().toString().c_str());
  } else {
    Serial.println("\n❌ WiFi connect timeout. Restarting in 3s...");
    delay(3000);
    ESP.restart();
  }
}

String remapGetPath(const String& path) {
#if USE_DEMO_ECHO
  if (path == "/health") return "/status/200";
  if (path == "/grid-status") return "/get"; // generic GET echo
  return "/get"; // default
#else
  return path;
#endif
}

String remapPostPath(const String& path) {
#if USE_DEMO_ECHO
  return "/post"; // echo POST
#else
  return path;
#endif
}

bool httpGet(const String& path, String& bodyOut, int& codeOut) {
  WiFiClientSecure client;
  client.setInsecure(); // disable TLS cert validation for quick demo

  HTTPClient http;
  String url = String(BACKEND_BASE) + path;
  Serial.printf("\n➡️ GET %s\n", url.c_str());

  if (!http.begin(client, url)) {
    Serial.println("HTTP begin failed");
    return false;
  }

  int code = http.GET();
  codeOut = code;
  if (code > 0) {
    bodyOut = http.getString();
    Serial.printf("⬅️ %d\n%s\n", code, bodyOut.c_str());
  } else {
    Serial.printf("❌ GET failed, error: %s\n", http.errorToString(code).c_str());
  }
  http.end();
  return code > 0 && code < 400;
}

bool httpPostJson(const String& path, const String& json, String& bodyOut, int& codeOut) {
  WiFiClientSecure client;
  client.setInsecure(); // disable TLS cert validation for quick demo

  HTTPClient http;
  String url = String(BACKEND_BASE) + path;
  Serial.printf("\n➡️ POST %s\nBody: %s\n", url.c_str(), json.c_str());

  if (!http.begin(client, url)) {
    Serial.println("HTTP begin failed");
    return false;
  }

  http.addHeader("Content-Type", "application/json");
  int code = http.POST(json);
  codeOut = code;
  if (code > 0) {
    bodyOut = http.getString();
    Serial.printf("⬅️ %d\n%s\n", code, bodyOut.c_str());
  } else {
    Serial.printf("❌ POST failed, error: %s\n", http.errorToString(code).c_str());
  }
  http.end();
  return code > 0 && code < 400;
}

bool demoStressed = false; // used only in echo mode

bool isGridStressedFromJson(const String& json) {
#if USE_DEMO_ECHO
  // In echo mode, we simulate grid status locally while still performing a GET
  return demoStressed;
#else
  // super naive check sufficient for: {"status":"STRESSED"}
  return json.indexOf("\"STRESSED\"") >= 0;
#endif
}

void indicateStatus(bool stressed) {
  digitalWrite(LED_BUILTIN, stressed ? HIGH : LOW);
}

// Simple blocking blink patterns for quick demo
void blinkPattern(int times, int onMs, int offMs) {
  for (int i = 0; i < times; i++) {
    digitalWrite(LED_BUILTIN, HIGH);
    delay(onMs);
    digitalWrite(LED_BUILTIN, LOW);
    if (i < times - 1) delay(offMs);
  }
}

bool getHealth() {
  String body; int code;
  bool ok = httpGet("/health", body, code);
  if (ok) {
    Serial.println("Health OK (button)");
    blinkPattern(1, 500, 0); // one long blink
  } else {
    Serial.println("Health check failed (button)");
    blinkPattern(3, 120, 120); // triple quick blinks
  }
  return ok;
}

bool getGridStatusButton() {
  String body; int code;
  bool ok = httpGet("/grid-status", body, code);
  if (ok) {
    bool stressed = isGridStressedFromJson(body);
    indicateStatus(stressed); // steady LED reflects status
    Serial.printf("Button grid-status: %s\n", stressed ? "STRESSED" : "normal");
    blinkPattern(2, 180, 180); // ack with two blinks
  } else {
    Serial.println("grid-status failed (button)");
    blinkPattern(3, 120, 120);
  }
  return ok;
}

bool triggerStressEvent() {
#if USE_DEMO_ECHO
  demoStressed = true; // simulate stress
#endif
  String resp; int code;
  // No body needed per spec; send empty JSON
  bool ok = httpPostJson("/simulate-stress-event", "{}", resp, code);
  if (ok) {
    Serial.println("Triggered stress event via button press.");
    blinkPattern(1, 80, 0);  // quick ack
  } else {
    Serial.println("Failed to trigger stress event.");
    blinkPattern(3, 120, 120);
  }
  return ok;
}

bool manualReportSavings() {
  String payload = String("{") +
                   "\"deviceAddress\":\"" + DEVICE_ADDRESS + "\"," +
                   "\"savings\":" + String(SAVINGS_WATTS) +
                   "}";
  String resp; int code;
  bool ok = httpPostJson("/report-savings", payload, resp, code);
  if (ok) {
    Serial.println("Manual savings report sent (double-click).");
    blinkPattern(2, 80, 80); // double quick ack
  } else {
    Serial.println("Manual savings report failed.");
    blinkPattern(3, 120, 120);
  }
  return ok;
}

void handleButton() {
  int reading = digitalRead(BUTTON_PIN);
  unsigned long now = millis();

  // Debounce
  if (reading != lastButtonReading) {
    lastDebounceTime = now;
    lastButtonReading = reading;
  }
  if ((now - lastDebounceTime) <= DEBOUNCE_MS) {
    return;
  }

  // Edge detection
  if (reading != stableButtonState) {
    stableButtonState = reading;
    if (stableButtonState == LOW) {
      // Pressed
      buttonPressed = true;
      pressStartMs = now;
    } else {
      // Released
      if (buttonPressed) {
        unsigned long pressLen = now - pressStartMs;
        buttonPressed = false;
        if (pressLen >= VERY_LONGPRESS_MS) {
          // Very long press: toggle Test Mode
          testMode = !testMode;
          Serial.printf("%s Test Mode\n", testMode ? "Entered" : "Exited");
          blinkPattern(1, testMode ? 600 : 120, 0);
          // Reset click tracking
          clickCount = 0;
          waitingForSecondClick = false;
        } else if (pressLen >= LONGPRESS_MS) {
          // Long press: GET /health
          Serial.println("Long press: GET /health");
          getHealth();
          // Reset click tracking
          clickCount = 0;
          waitingForSecondClick = false;
        } else {
          // Short click
          clickCount++;
          lastReleaseMs = now;
          waitingForSecondClick = true;
        }
      }
    }
  }

  // Double-click timeout handling
  if (waitingForSecondClick && (now - lastReleaseMs > CLICK_TIMEOUT_MS)) {
    // Interpret clicks
    if (clickCount >= 3) {
      // Triple-click: GET /grid-status
      Serial.println("Triple-click detected: GET /grid-status");
      getGridStatusButton();
    } else if (clickCount == 2) {
      // Double-click: manual report savings
      Serial.println("Double-click detected: manual report savings");
      manualReportSavings();
    } else if (clickCount == 1) {
      // Single click: trigger stress event
      Serial.println("Single click detected: trigger stress event");
      triggerStressEvent();
    }
    // Reset click state
    clickCount = 0;
    waitingForSecondClick = false;
  }

  // No additional live long-press action here; handled in release logic above
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  indicateStatus(false);
  connectWiFi();

  // Optional: ping health endpoint at boot
  String body; int code;
  if (httpGet("/health", body, code)) {
    Serial.println("Health OK");
  } else {
    Serial.println("Health check failed (continuing anyway)");
  }
}

void loop() {
  // Ensure WiFi stays connected
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi lost. Reconnecting...");
    connectWiFi();
  }

  unsigned long now = millis();
  handleButton();

  // Hardware Test Mode: blink LED and print button state; skip network actions
  if (testMode) {
    if (now - lastBlinkMs >= 250) {
      lastBlinkMs = now;
      blinkState = !blinkState;
      digitalWrite(LED_BUILTIN, blinkState ? HIGH : LOW);
    }
    static unsigned long lastPrint = 0;
    if (now - lastPrint >= 500) {
      lastPrint = now;
      Serial.printf("[TEST] Button=%s\n", digitalRead(BUTTON_PIN) == LOW ? "PRESSED" : "RELEASED");
    }
    delay(5); // keep loop responsive
    return;
  }

  if (now - lastPollMs >= POLL_INTERVAL_MS) {
    lastPollMs = now;

    String body; int code;
    bool ok = httpGet("/grid-status", body, code);
    if (!ok) {
      Serial.println("Failed to fetch grid status.");
      return; // try again next cycle
    }

    bool stressed = isGridStressedFromJson(body);
    indicateStatus(stressed);
    Serial.printf("Grid status: %s\n", stressed ? "STRESSED" : "normal");

    if (stressed && !reportedForThisStress) {
      // Report savings once per stress event
      String payload = String("{") +
                       "\"deviceAddress\":\"" + DEVICE_ADDRESS + "\"," +
                       "\"savings\":" + String(SAVINGS_WATTS) +
                       "}";

      String resp; int postCode;
      bool postOk = httpPostJson("/report-savings", payload, resp, postCode);
      if (postOk) {
        Serial.println("Savings reported successfully.");
        reportedForThisStress = true;
      } else {
        Serial.println("Failed to report savings. Will retry next cycle.");
      }
    }

    if (!stressed) {
#if USE_DEMO_ECHO
      // In echo mode, auto-return to normal after one report to mimic backend resolution
      if (reportedForThisStress) {
        demoStressed = false;
      }
#endif
      // Reset for next event
      if (reportedForThisStress) {
        Serial.println("Grid back to normal. Resetting report flag.");
      }
      reportedForThisStress = false;
    }
  }
}
