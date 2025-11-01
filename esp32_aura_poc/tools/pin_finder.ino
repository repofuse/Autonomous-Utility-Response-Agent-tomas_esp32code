/*
  ESP32 Pin Finder (LED + Button)
  Purpose: Quickly discover the correct GPIO for the onboard LED and your button using Serial Monitor.

  How it works:
  - LED finder: cycles through candidate pins and blinks each 3 times; watch which one actually toggles the LED.
  - Button finder: sets many pins to INPUT_PULLUP and reports any pin that reads LOW when you press/release your button.

  Usage:
  1) Open Serial Monitor at 115200
  2) Watch the LED blink sequence and note the GPIO printed just before the LED blinks
  3) Press your button (connected to some GPIO and GND); see which GPIO is reported as PRESSED/RELEASED

  Notes:
  - Avoid using strapping pins for buttons if possible (GPIO0, GPIO2, GPIO4, GPIO12, GPIO15) as they affect boot.
  - Some boards have multiple LEDs or external drivers; only the true onboard LED will visibly blink.
*/

#include <Arduino.h>

// Candidate pins to test for LED (common ESP32 boards)
int LED_CANDIDATES[] = {2, 4, 5, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 32, 33};
const int LED_CAND_COUNT = sizeof(LED_CANDIDATES)/sizeof(LED_CANDIDATES[0]);

// Candidate pins to scan for button (INPUT_PULLUP)
int BTN_CANDIDATES[] = {0, 2, 4, 5, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 32, 33, 34, 35, 36, 39};
const int BTN_CAND_COUNT = sizeof(BTN_CANDIDATES)/sizeof(BTN_CANDIDATES[0]);

// Track last states for button candidates
int lastBtnState[40]; // index by GPIO number directly for simplicity; valid ESP32 pins only

void blinkPin(int gpio, int times, int onMs, int offMs) {
  pinMode(gpio, OUTPUT);
  for (int i = 0; i < times; i++) {
    digitalWrite(gpio, HIGH);
    delay(onMs);
    digitalWrite(gpio, LOW);
    if (i < times - 1) delay(offMs);
  }
  // leave as OUTPUT LOW
}

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n=== ESP32 Pin Finder ===");
  Serial.println("This will blink through likely LED pins, then scan for a button on INPUT_PULLUP.");

  // Initialize button candidate pins
  for (int i = 0; i < BTN_CAND_COUNT; i++) {
    int gpio = BTN_CANDIDATES[i];
    // Note: some inputs (34-39) are input-only and do not have pull-ups on some modules.
    pinMode(gpio, INPUT_PULLUP);
    lastBtnState[gpio] = digitalRead(gpio);
  }

  // LED finder phase
  Serial.println("\n--- LED Finder: Watching for LED blink ---");
  for (int i = 0; i < LED_CAND_COUNT; i++) {
    int gpio = LED_CANDIDATES[i];
    Serial.printf("Trying GPIO %d for LED...\n", gpio);
    blinkPin(gpio, 3, 150, 150);
    delay(300);
  }
  Serial.println("\nIf you saw the onboard LED blink, note the GPIO printed just before the blink.");
  Serial.println("Proceeding to button scan... Press and release your button now.");
}

unsigned long lastPrint = 0;

void loop() {
  // Button finder phase: scan all candidates and report changes
  for (int i = 0; i < BTN_CAND_COUNT; i++) {
    int gpio = BTN_CANDIDATES[i];
    int state = digitalRead(gpio);
    if (state != lastBtnState[gpio]) {
      lastBtnState[gpio] = state;
      if (state == LOW) {
        Serial.printf("GPIO %d PRESSED (reads LOW on INPUT_PULLUP)\n", gpio);
      } else {
        Serial.printf("GPIO %d RELEASED (reads HIGH on INPUT_PULLUP)\n", gpio);
      }
    }
  }

  // Periodic reminder
  unsigned long now = millis();
  if (now - lastPrint > 3000) {
    lastPrint = now;
    Serial.println("(Tip) If nothing prints when you press, move one wire from the button to a different GPIO and try again.");
  }
  delay(20);
}
