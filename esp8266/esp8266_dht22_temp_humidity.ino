
#include "DHT.h"
#define DHTPIN 2
#define DHTTYPE DHT22
#define SENSOR_DOUBLE_READ_DELAY 3000
DHT dht(DHTPIN, DHTTYPE, 15);

#include <ESP8266WiFi.h>
// don't leave real values here, after the first run
#define WLAN_SSID "SOME_SSID"
#define WLAN_PASS "SOME_PASS"

#include <ESP8266HTTPClient.h>
HTTPClient http;

#define REPORT_INTERVAL 10000

void setup() {
  dht.begin();

  Serial.begin(115200);
  delay(10);
  Serial.println();
  Serial.println();

  WiFi.mode(WIFI_STA);

  Serial.print(F("Connecting to "));
  Serial.print(WLAN_SSID);

  // Run this once this way, with the real SSID and PASS, and they will be cached on the device.
  //WiFi.begin(WLAN_SSID, WLAN_PASS);
  // From then on, run it this way, so you don't have to store the network password in source.
  WiFi.begin();

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(F("."));
  }
  Serial.println();

  Serial.println(F("WiFi connected"));
  Serial.print(F("IP address: "));
  Serial.println(WiFi.localIP());
}

void loop() {
  if (WiFi.status() != WL_CONNECTED)
  {
    Serial.println(F("Wifi not connected; resetting..."));
    ESP.restart();
  }

  // Get the sensor data twice;
  // it seems to return the value that it saw immediately after the previous value was retrieved,
  // no matter how long ago that was.
  float humidity = dht.readHumidity();
  float temp = dht.readTemperature();
  delay(SENSOR_DOUBLE_READ_DELAY);

  humidity = dht.readHumidity();
  Serial.print(F("Humidity: "));
  Serial.println(humidity);

  temp = dht.readTemperature(); // pass 'true' to get Fahrenheit
  Serial.print(F("Temperature: "));
  Serial.println(temp);

  Serial.println("HTTP begin...");
  char *url = makeUrl(ESP.getChipId(), temp, humidity);
  if (http.begin(url)) {
    int httpCode = http.GET();
    if (httpCode == HTTP_CODE_OK) {
      Serial.println(http.getString());
    } else {
      Serial.printf("GET failed, error: %s\n", http.errorToString(httpCode).c_str());
    }

    http.end();
  } else {
    Serial.printf("Unable to connect\n");
  }

  delay(REPORT_INTERVAL - SENSOR_DOUBLE_READ_DELAY);
}

char * makeUrl(int chipId, float temp, float humidity) {
  char url[255] = "http://weather.rainskit.com/submit?source=";

  char temp_str[10];
  itoa(chipId, temp_str, 20);
  strcat(url, temp_str);

  strcat(url, "&temperature=");
  dtostrf(temp, 4, 1, temp_str);
  strcat(url, temp_str);

  strcat(url, "&humidity=");
  dtostrf(humidity, 4, 1, temp_str);
  strcat(url, temp_str);

  return url;
}
