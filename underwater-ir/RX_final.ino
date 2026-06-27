#include <Arduino.h>
#include <IRremoteESP8266.h>
#include <IRrecv.h>
#include <IRutils.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

const uint16_t kRecvPin = 14; // IR Receiver Pin (D5 = GPIO14)

IRrecv irrecv(kRecvPin);
decode_results results;

LiquidCrystal_I2C lcd(0x27, 16, 2); // LCD (change address if needed: 0x27 or 0x3F)

String recievedText = ""; // String for storing all characters in message

void setup() {
  irrecv.enableIRIn();  // Start IR receiver

  // LCD setup
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("IR RX Ready!");
}

void loop() {
  if (irrecv.decode(&results)) { // Checks if received message is decoded

    Serial.println(results.value, HEX); 
    //Convert to Char
    if (results.value == 0x00FF00FF) {
     recievedText = "";   // Clears LCD before displaying new message
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("no");  // Displays spaces
   }
  else{
  char receivedChar = (char)results.value;
  recievedText += receivedChar;
    lcd.setCursor(0, 0);
    lcd.print("IR Code:");
    lcd.setCursor(0, 1);
    lcd.print(recievedText);
  }
   irrecv.resume();   // receive next
  }

  delay(100);
}



