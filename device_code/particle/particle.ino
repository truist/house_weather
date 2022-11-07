
///////////////////////////////////////////////////////////////
// Don't try to use this here                                //
// You have to do it from the Particle IDE (i.e. on the web) //
// https://build.particle.io/build/5c1b120d7b21e710f300172d  //
///////////////////////////////////////////////////////////////

#include <PietteTech_DHT.h>
#include <HttpClient.h>

#define DHTTYPE DHT22
#define DHTPIN D5
PietteTech_DHT DHT(DHTPIN, DHTTYPE);

#define LEDPIN D7

#define REPORT_INTERVAL 180000

HttpClient http;
http_response_t response;
http_request_t request;
char path[128];

void setup() {
    pinMode(LEDPIN, OUTPUT);
    digitalWrite(LEDPIN, HIGH);

    DHT.begin();
}

void loop() {
    digitalWrite(LEDPIN, HIGH);

    int result = DHT.acquireAndWait(5000);
    if (result != DHTLIB_OK) {
        Particle.publish("DHT read error");
        delay(10000);
        return;
    }

    float humidity = DHT.getHumidity();
    Particle.publish("humidity", String::format("%.1f", humidity));

    float temp = DHT.getCelsius();
    Particle.publish("temp", String::format("%.1f", temp));

    sprintf(path,
        "/submit?source=photon&temperature=%.1f&humidity=%.1f",
        temp,
        humidity);
    Particle.publish("path", path);

    request.hostname = "weather.rainskit.com";
    request.port = 80;
    request.path = path;

    http.get(request, response);

    Particle.publish("HTTP response status", String(response.status));

    digitalWrite(LEDPIN, LOW);

    delay(REPORT_INTERVAL);
}
