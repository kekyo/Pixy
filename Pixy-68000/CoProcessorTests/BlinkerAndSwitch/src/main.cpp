#include <Arduino.h>
#include <SPI.h>

#define DIO0 PIN_PC0
#define DIO1 PIN_PC1
#define SCLK PIN_PC2
#define RCLK PIN_PC3

#define LED0 PIN_PC4
#define LED1 PIN_PC5
#define LED2 PIN_PD4
#define LED3 PIN_PD5

#define SW0 PIN_PB0
#define SW1 PIN_PB1
#define SW2 PIN_PB2
#define SW3 PIN_PD6
#define SW4 PIN_PD7

static const byte digitPatterns[16] = {
  B11000000,  // 0
  B11111001,  // 1
  B10100100,  // 2
  B10110000,  // 3
  B10011001,  // 4
  B10010010,  // 5
  B10000010,  // 6
  B11111000,  // 7
  B10000000,  // 8
  B10010000,  // 9
  B10001000,  // a
  B10000011,  // b
  B11000110,  // c
  B10100001,  // d
  B10000110,  // e
  B10001110   // f
};

///////////////////////////////////////////////////////////

static const SPISettings spiSettings(1000000, MSBFIRST, SPI_MODE0);

static void outputBits(byte value) {
  for (int j = 0; j < 8; j++) {
    digitalWrite(DIO0, (value & 0x80) ? HIGH : LOW);
    digitalWrite(DIO1, (value & 0x80) ? HIGH : LOW);
    digitalWrite(SCLK, LOW);
    digitalWrite(SCLK, HIGH);
    value <<= 1;
  }
}

static void flush() {
    digitalWrite(RCLK, LOW);
    digitalWrite(RCLK, HIGH);
}

static void output4Segments(uint16_t value, bool isHigh) {
  byte column = isHigh ? 0x80 : 0x08;
  for (int i = 0; i < 4; i++) {
    // Makes value bits
    byte v0 = digitPatterns[value & 0x0f];
    outputBits(v0);
    // Makes column bits
    outputBits(column);
    value >>= 4;
    column >>= 1;
    flush();
  }
}

///////////////////////////////////////////////////////////

void setup() {
  Serial.begin(115200);
  Serial.println("setup()");

  pinMode(LED0, OUTPUT);
  pinMode(LED1, OUTPUT);
  pinMode(LED2, OUTPUT);
  pinMode(LED3, OUTPUT);
  digitalWrite(LED0, HIGH);
  digitalWrite(LED1, HIGH);
  digitalWrite(LED2, HIGH);
  digitalWrite(LED3, HIGH);

  pinMode(SW0, INPUT);
  pinMode(SW1, INPUT);
  pinMode(SW2, INPUT);
  pinMode(SW3, INPUT);
  pinMode(SW4, INPUT);

  pinMode(DIO0, OUTPUT);
  pinMode(DIO1, OUTPUT);
  pinMode(SCLK, OUTPUT);
  pinMode(RCLK, OUTPUT);

  digitalWrite(SCLK, HIGH);
  digitalWrite(RCLK, HIGH);
}

static uint32_t value = 0;

void loop() {
  digitalWrite(LED0, digitalRead(SW0) ? LOW : HIGH);
  digitalWrite(LED1, digitalRead(SW1) ? LOW : HIGH);
  digitalWrite(LED2, digitalRead(SW2) ? LOW : HIGH);
  digitalWrite(LED3, digitalRead(SW3) ? LOW : HIGH);
  
  if (!digitalRead(SW4)) {
    digitalWrite(LED0, HIGH);
    digitalWrite(LED1, HIGH);
    digitalWrite(LED2, HIGH);
    digitalWrite(LED3, HIGH);

    Serial.println("SW4 bang.");
  }

  output4Segments((value >> 16) & 0xffffffff, true);
  output4Segments(value & 0xffffffff, false);

  outputBits(0);
  outputBits(0);
  flush();

  value++;
}
