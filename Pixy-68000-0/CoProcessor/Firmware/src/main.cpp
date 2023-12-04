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
#define SW2 PIN_PB7
#define SW3 PIN_PD6
#define SW4 PIN_PD7

#define SPISS PIN_PB2
#define SPISI PIN_PB3
#define SPISO PIN_PB4
#define SPICLK PIN_PB5

#define REQINT PIN_PD2
#define PROGRAMN PIN_PD3

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

static void outputBits(byte row0, byte row1) {
  for (int j = 0; j < 8; j++) {
    digitalWrite(DIO0, (row0 & 0x80) ? HIGH : LOW);
    digitalWrite(DIO1, (row1 & 0x80) ? HIGH : LOW);
    digitalWrite(SCLK, LOW);
    digitalWrite(SCLK, HIGH);
    row0 <<= 1;
    row1 <<= 1;
  }
}

static void flush() {
    digitalWrite(RCLK, LOW);
    digitalWrite(RCLK, HIGH);
}

static void output4Segments(uint16_t row0, uint16_t row1, bool isHigh) {
  byte column = isHigh ? 0x80 : 0x08;
  for (int i = 0; i < 4; i++) {
    // Makes value bits
    byte v0 = digitPatterns[row0 & 0x0f];
    byte v1 = digitPatterns[row1 & 0x0f];
    outputBits(v0, v1);
    // Makes column bits
    outputBits(column, column);
    row0 >>= 4;
    row1 >>= 4;
    column >>= 1;
    flush();
  }
}

static void outputSegments(uint32_t row0, uint32_t row1) {
  output4Segments((row0 >> 16) & 0xffffffff, (row1 >> 16) & 0xffffffff, true);
  output4Segments(row0 & 0xffffffff, row1 & 0xffffffff, false);
}

///////////////////////////////////////////////////////////

void setup() {
  Serial.begin(115200);
  Serial.println("setup()");

  SPI.begin();

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

  pinMode(SPISS, OUTPUT);
  digitalWrite(SPISS, HIGH);

  pinMode(PROGRAMN, INPUT);
}

static const SPISettings spiSettings(100000, MSBFIRST, SPI_MODE1);
static bool resetting = false;

void loop() {
  digitalWrite(LED0, digitalRead(SW0) ? LOW : HIGH);
  digitalWrite(LED1, digitalRead(SW1) ? LOW : HIGH);
  digitalWrite(LED2, digitalRead(SW2) ? LOW : HIGH);
  digitalWrite(LED3, digitalRead(SW3) ? LOW : HIGH);
  
  if (!digitalRead(SW4)) {
    if (!resetting) {
      digitalWrite(PROGRAMN, LOW);
      pinMode(PROGRAMN, OUTPUT);
      resetting = true;
    }
  } else {
    if (resetting) {
      pinMode(PROGRAMN, INPUT);
      digitalWrite(PROGRAMN, HIGH);
      resetting = false;
    }
  }

  SPI.beginTransaction(spiSettings);
  digitalWrite(SPISS, LOW);
  uint8_t buf[5];
  memset(buf, 0, sizeof buf);
  SPI.transfer(&buf, sizeof buf);
  digitalWrite(SPISS, HIGH);
  SPI.endTransaction();

  const uint32_t addr = buf[2] | ((uint32_t)buf[1] << 8) | ((uint32_t)buf[0] << 16);
  const uint32_t data = buf[4] | ((uint32_t)buf[3] << 8);
  outputSegments(addr, data);

  outputBits(0, 0);
  outputBits(0, 0);
  flush();
}