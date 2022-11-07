
#include "DHT.h"
#define DHTPIN 2
#define DHTTYPE DHT22
#define SENSOR_DOUBLE_READ_DELAY 3000
DHT dht(DHTPIN, DHTTYPE, 15);

#include <ESP8266WiFi.h>
// don't leave real values here, after the first run
#define WLAN_SSID "FAKE_SSID"
#define WLAN_PASS "FAKE_PASS"

#include <ESP8266HTTPClient.h>
HTTPClient http;

#define REPORT_INTERVAL 180000

void setup() {
  dht.begin();

  Serial.begin(115200);
  delay(10);
  Serial.println();
  Serial.println();

  WiFi.mode(WIFI_STA);

  Serial.printf("Connecting to %s\n", WLAN_SSID);

  // Run this once this way, with the real SSID and PASS, and they will be cached on the device.
  WiFi.begin(WLAN_SSID, WLAN_PASS);
  // From then on, run it this way, so you don't have to store the network password in source.
  //WiFi.begin();

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();

  Serial.println("WiFi connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void loop() {
  if (WiFi.status() != WL_CONNECTED)
  {
    Serial.println("Wifi not connected; resetting...");
    ESP.restart();
  }

  // Get the sensor data twice;
  // it seems to return the value that it saw immediately after the previous value was retrieved,
  // no matter how long ago that was.
  float humidity = dht.readHumidity();
  float temp = dht.readTemperature();
  delay(SENSOR_DOUBLE_READ_DELAY);

  humidity = dht.readHumidity();
  Serial.printf("Humidity: %f\n", humidity);

  temp = dht.readTemperature(); // pass 'true' to get Fahrenheit
  Serial.printf("Temperature: %f\n", temp);

  int chipId = ESP.getChipId();
  Serial.printf("ChipId: %X\n", chipId);
  char temp_str[20];
  itoa(chipId, temp_str, 20);
  Serial.printf("ChipID (base 20 - old implementation bug): %s\n", temp_str);

  Serial.println("HTTP begin...");

  char url[255];
  sprintf(url, "http://weather.rainskit.com/submit?source=%X&temperature=%.1f&humidity=%.1f", chipId, temp, humidity);
  Serial.println(url);

  WiFiClient client;
  if (http.begin(client, url)) {
    int httpCode = http.GET();
    if (httpCode == HTTP_CODE_OK) {
      Serial.println(http.getString());
    } else {
      Serial.printf("GET failed, error: %s\n", http.errorToString(httpCode).c_str());
    }

    http.end();
  } else {
    Serial.println("Unable to connect");
  }

  delay(REPORT_INTERVAL - SENSOR_DOUBLE_READ_DELAY);
}
