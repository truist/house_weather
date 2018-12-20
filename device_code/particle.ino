#include <Adafruit_DHT.h>
#include <HttpClient.h>

#define DHTTYPE DHT22
#define DHTPIN D5
#define SENSOR_DOUBLE_READ_DELAY 3000
DHT dht(DHTPIN, DHTTYPE);

#define LEDPIN D7

#define REPORT_INTERVAL 180000

HttpClient http;
http_response_t response;
http_request_t request;
char path[128];

void setup() {
    pinMode(LEDPIN, OUTPUT);
    digitalWrite(LEDPIN, HIGH);

    dht.begin();
}

void loop() {
    digitalWrite(LEDPIN, HIGH);

    // Get the sensor data twice;
    // it seems to return the value that it saw immediately after the previous value was retrieved,
    // no matter how long ago that was.
    float humidity = dht.getHumidity();
    float temp = dht.getTempCelcius();
    delay(SENSOR_DOUBLE_READ_DELAY);
    humidity = dht.getHumidity();
    temp = dht.getTempCelcius();

    sprintf(path,
        "/submit?source=photon&temperature=%.2f&humidity=%.2f",
        temp,
        humidity);

    request.hostname = "weather.rainskit.com";
    request.port = 80;
    request.path = path;

    http.get(request, response);

    digitalWrite(LEDPIN, LOW);

    delay(REPORT_INTERVAL - SENSOR_DOUBLE_READ_DELAY);
}


