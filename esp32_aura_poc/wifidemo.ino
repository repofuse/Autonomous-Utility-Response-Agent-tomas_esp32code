#include <WiFi.h>

const char* ssid = "TatianaSF.com";          // Replace with your Wi-Fi network name
const char* password = "TatianaSF.com";  // Replace with your Wi-Fi password

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  Serial.println("Connecting to Wi-Fi...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWi-Fi connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  // Nothing to do here
}   