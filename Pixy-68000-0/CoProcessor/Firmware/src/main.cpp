#include <Arduino.h>
#include <TimerOne.h>
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

///////////////////////////////////////////////////////////

class LedSegment
{
private:
  static const uint8_t digitPatterns[16];

  static inline void outputBits(uint8_t row0, uint8_t row1) {
    for (int j = 0; j < 8; j++) {
      digitalWrite(DIO0, (row0 & 0x80) ? HIGH : LOW);
      digitalWrite(DIO1, (row1 & 0x80) ? HIGH : LOW);
      digitalWrite(SCLK, LOW);
      digitalWrite(SCLK, HIGH);
      row0 <<= 1;
      row1 <<= 1;
    }
  }

  static inline void flush() {
    digitalWrite(RCLK, LOW);
    digitalWrite(RCLK, HIGH);
  }

  static inline void clear() {
    outputBits(0, 0);
    outputBits(0, 0);
    flush();
  }

  uint8_t state;
  uint8_t column;
  uint8_t count;
  uint16_t row0h;
  uint16_t row1h;
  uint32_t row0;
  uint32_t row1;

  void emitCurrent() {
    // Makes value bits
    uint8_t v0 = digitPatterns[row0h & 0x0f];
    uint8_t v1 = digitPatterns[row1h & 0x0f];
    outputBits(v0, v1);
    // Makes column bits
    outputBits(column, column);
    row0h >>= 4;
    row1h >>= 4;
    column >>= 1;
    flush();
  }

public:
  LedSegment() :
    state(0), column(0x80), count(0), row0h(0), row1h(0), row0(0), row1(0) {
  }

  inline void set(uint32_t row0, uint32_t row1) {
    this->row0 = row0;
    this->row1 = row1;
  }

  inline void emit() {
    switch (state) {
      // Draw upper 4 columns.
      case 0:
        // Emit to segments.
        emitCurrent();
        count++;
        if (count >= 4) {
          // To lower 4 columns.
          column = 0x08;
          row0h = (uint16_t)row0;
          row1h = (uint16_t)row1;
          count = 0;
          state = 1;
        }
        break;
      // Draw lower 4 columns.
      case 1:
        // Emit to segments.
        emitCurrent();
        count++;
        if (count >= 4) {
          state = 2;
        }
        break;
      // Blanking.
      default:
        clear();
        // To upper 4 columns.
        column = 0x80;
        row0h = (uint16_t)(row0 >> 16);
        row1h = (uint16_t)(row1 >> 16);
        count = 0;
        state = 0;
        break;
    }
  }
};

const uint8_t LedSegment::digitPatterns[16] = {
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

#define SPI_SPEED 8000000
//#define SPI_SPEED 100000
#define TIMER_INTERVAL 2000  // usec

#define SW_BITS 0
#define UART_RECEIVE_BYTES 1
#define LED_BITS 5
#define UART_SEND_BYTES 6

static const SPISettings spiSettings(SPI_SPEED, LSBFIRST, SPI_MODE1);
static uint8_t spiBuffer[7];   // 56bits

static bool resetting = false;

static LedSegment ledSegment;

static void timerHandler() {
  ledSegment.emit();
}

// Setup.
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

  Timer1.initialize(TIMER_INTERVAL);
  Timer1.attachInterrupt(timerHandler);
}

///////////////////////////////////////////////////////////

// Loop handler.
void loop() {
  // Assert reset to FPGA (68000).
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

  // Store switch bits into the SPI buffer.
  memset(spiBuffer, 0, sizeof spiBuffer);
  spiBuffer[SW_BITS] =
    (digitalRead(SW0) ? 0x00 : 0x01) |
    (digitalRead(SW1) ? 0x00 : 0x02) |
    (digitalRead(SW2) ? 0x00 : 0x04) |
    (digitalRead(SW3) ? 0x00 : 0x08);

  // Store serial one byte.
  if (Serial.available()) {
    spiBuffer[SW_BITS] |= 0x10;
    spiBuffer[UART_RECEIVE_BYTES] = (uint8_t)Serial.read();
  }

  // Polling by SPI.
  SPI.beginTransaction(spiSettings);
  digitalWrite(SPISS, LOW);
  SPI.transfer(spiBuffer, sizeof spiBuffer);
  digitalWrite(SPISS, HIGH);
  SPI.endTransaction();

  // Extracts 68000 address and data bus bits.
  // It is little endian format.
  const uint32_t addr = spiBuffer[0] | ((uint32_t)spiBuffer[1] << 8) | ((uint32_t)spiBuffer[2] << 16);
  const uint32_t data = spiBuffer[3] | ((uint32_t)spiBuffer[4] << 8);
  ledSegment.set(addr, data);

  // Extracts output signals to drive LEDs.
  const uint8_t outputSignal = spiBuffer[LED_BITS];
  digitalWrite(LED0, (outputSignal & 0x01) ? HIGH : LOW);
  digitalWrite(LED1, (outputSignal & 0x02) ? HIGH : LOW);
  digitalWrite(LED2, (outputSignal & 0x04) ? HIGH : LOW);
  digitalWrite(LED3, (outputSignal & 0x08) ? HIGH : LOW);

  const uint8_t uartSendSize = spiBuffer[LED_BITS] >> 4;
  if (uartSendSize) {
    const uint8_t uartSendBytes = spiBuffer[UART_SEND_BYTES];
    Serial.print(static_cast<char>(uartSendBytes));
  }
}
