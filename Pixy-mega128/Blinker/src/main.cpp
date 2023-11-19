#include <Arduino.h>

int count = 0;

void setup() {
  Serial.begin(115200);
  Serial.println("setup()");
  
  pinMode(PIN_PB5, OUTPUT);
  pinMode(PIN_PB6, OUTPUT);
  pinMode(PIN_PB7, OUTPUT);
}

void loop() {
  Serial.println("Hello World! " + String(count));
  int v = count & 0x07;
  
  if (v & 0x01)
    digitalWrite(PIN_PB5, HIGH);
  else
    digitalWrite(PIN_PB5, LOW);

  if (v & 0x02)
    digitalWrite(PIN_PB6, HIGH);
  else
    digitalWrite(PIN_PB6, LOW);
  
  if (v & 0x04)
    digitalWrite(PIN_PB7, HIGH);
  else
    digitalWrite(PIN_PB7, LOW);

  delay(500);
  count++;
}
