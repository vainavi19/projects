#include <Arduino.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>
#include <WiFi.h>

const uint16_t IR_LED_PIN = 23; //Pin coonected to Anode of IR LED 

IRsend irsend(IR_LED_PIN);

String message = ""; // Defining empty string for messgae to be transmitted
bool newMessage = false; // Marker raised (true) when message received from webpage; False after transmission
bool isSending = false; // Marker raised (true) while transmitting to RX; False after transmission

const char* ssid = "ESP32_IR"; // WiFi AP 
const char* password = "12345678";

WiFiServer server(80);


void setup() {
  WiFi.softAP(ssid, password);  // Start WiFi AP

  server.begin();
  irsend.begin();
}

void loop() {
  WiFiClient client = server.available();

  if (client) {
    String request = client.readStringUntil('\r');
    client.flush();

    // Extract data from URL: /send?data=HELLO
    if (request.indexOf("/send?data=") != -1) {

      int start = request.indexOf("data=") + 5;
      int end = request.indexOf(' ', start);
      message = request.substring(start, end);
      message.replace('+', ' ');   

      newMessage = true;
    }

    // Webpage
    client.println("HTTP/1.1 200 OK");
    client.println("Content-Type: text/html");
    client.println();

    client.println("<h2> IR Underwater Communication System </h2>");
    client.println("<form action=\"/send\">");
    client.println("<input type=\"text\" name=\"data\" placeholder=\"Enter text\">");
    client.println("<input type=\"submit\" value=\"Send\">");
    client.println("</form>");

    client.stop();
    
  } 

  
  if (newMessage && !isSending) {
  isSending = true;
  if (message) {
  irsend.sendNEC(0x00FF00FF, 32); // Start marker (Marker = 0x00FF00FF)
  delay(200);

  for (int i = 0; i < message.length(); i++) {
    uint32_t data = message[i];
    
    irsend.sendNEC(data, 32);
    delay(300);   // Duration between each character 
  }

 newMessage = false;
 isSending = false;
}
}
}
