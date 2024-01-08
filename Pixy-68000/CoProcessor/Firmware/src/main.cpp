#include <Arduino.h>
#include <TimerOne.h>
#include <SPI.h>

//-----------------------------------

#define BAUDRATE 38400
//#define BAUDRATE 115200
#define SPI_SPEED 8000000
//#define SPI_SPEED 100000

#define BITBANG 1
#define LOCAL_ECHO 0

//-----------------------------------

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
#if BITBANG
      const uint8_t bits = ((row0 & 0x80) >> 7) | ((row1 & 0x80) >> 6);
      PORTC = (PORTC & 0xfc) | bits;
      PORTC &= 0xfb;
      PORTC |= 0x04;
#else
      digitalWrite(DIO0, (row0 & 0x80) ? HIGH : LOW);
      digitalWrite(DIO1, (row1 & 0x80) ? HIGH : LOW);
      digitalWrite(SCLK, LOW);
      digitalWrite(SCLK, HIGH);
#endif
      row0 <<= 1;
      row1 <<= 1;
    }
  }

  static inline void flush() {
#if BITBANG
    PORTC &= 0xf7;
    PORTC |= 0x08;
#else
    digitalWrite(RCLK, LOW);
    digitalWrite(RCLK, HIGH);
#endif
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

#define TIMER_INTERVAL 1000  // usec

#define SW_BITS 0
#define UART_RECEIVE_BYTES 1
#define LED_BITS 5
#define UART_SEND_BYTES 6

static const SPISettings spiSettings(SPI_SPEED, LSBFIRST, SPI_MODE1);
static uint8_t spiBuffer[7];   // 56bits

static bool resetting = false;

#if !LOCAL_ECHO
static bool isReadyForReceive = false;
#endif

static LedSegment ledSegment;

static void timerHandler() {
  ledSegment.emit();
}

// Setup.
void setup() {
  Serial.begin(BAUDRATE);
  Serial.println();
  Serial.println("Pixy-68000 (c) Kouji Matsui (@kekyo@mastodon.cloud)");
  Serial.println();

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
#if BITBANG
  // Assert reset to FPGA (68000).
  if (!(PIND & 0x80)) {
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
#else
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
#endif

  // Store switch bits into the SPI buffer.
  //  MSB  -------------------------------------------------------------------------------------------  LSB
  //       | UART_RECEIVE_BYTE[7:0] | 0 | 0 | SEND_BUSY(0/1) | RECEIVE_DATA(0/1) | INPUT_SIGNAL[3:0] | ====>
  //       -------------------------------------------------------------------------------------------
  //memset(spiBuffer, 0, sizeof spiBuffer);
  spiBuffer[SW_BITS] =
    (digitalRead(SW0) ? 0x00 : 0x01) |
    (digitalRead(SW1) ? 0x00 : 0x02) |
    (digitalRead(SW2) ? 0x00 : 0x04) |
    (digitalRead(SW3) ? 0x00 : 0x08);

#if LOCAL_ECHO
  if (Serial.available() && Serial.availableForWrite()) {
    const uint8_t uartSendBytes = (uint8_t)Serial.read();
    Serial.print(static_cast<char>(uartSendBytes));
  }
#else
  // Store serial one byte when 68000 is ready for receiving.
  bool isSentThisIteration = false;
  if (isReadyForReceive && Serial.available()) {
    spiBuffer[SW_BITS] |= 0x10;
    spiBuffer[UART_RECEIVE_BYTES] = (uint8_t)Serial.read();
    isSentThisIteration = true;
    isReadyForReceive = false;
  }
#endif

  // Indicates send buffer availability.
  if (!Serial.availableForWrite()) {
    spiBuffer[SW_BITS] |= 0x20;    // SEND_BUSY
  }

  // Polling by SPI.
  SPI.beginTransaction(spiSettings);
#if BITBANG
  PORTB &= 0xfb;
#else
  digitalWrite(SPISS, LOW);
#endif
  SPI.transfer(spiBuffer, sizeof spiBuffer);
#if BITBANG
  PORTB |= 0x04;
#else
  digitalWrite(SPISS, HIGH);
#endif
  SPI.endTransaction();

  // Extracts 68000 address and data bus bits.
  // It is little endian format.
  //  MSB  ------------------------------------------------------------------------------------------------------------  LSB
  // ====> | UART_SEND_BYTE[7:0] | 0 | 0 | RECV_BUSY | SEND_DATA(1)    | OUTPUT_SIGNAL[3:0] | DATA[15:0] | ADDR[23:0] |
  //       ------------------------------------------------------------------------------------------------------------
  const uint32_t addr = spiBuffer[0] | ((uint32_t)spiBuffer[1] << 8) | ((uint32_t)spiBuffer[2] << 16);
  const uint32_t data = spiBuffer[3] | ((uint32_t)spiBuffer[4] << 8);
  ledSegment.set(addr, data);

  // Extracts output signals to drive LEDs.
  const uint8_t outputSignal = spiBuffer[LED_BITS];
  digitalWrite(LED0, (outputSignal & 0x01) ? HIGH : LOW);
  digitalWrite(LED1, (outputSignal & 0x02) ? HIGH : LOW);
  digitalWrite(LED2, (outputSignal & 0x04) ? HIGH : LOW);
  digitalWrite(LED3, (outputSignal & 0x08) ? HIGH : LOW);

#if !LOCAL_ECHO
  // Skip checking when this iteration already sent data.
  if (!isSentThisIteration) {
    // Apply for receiving readiness on 68000.
    isReadyForReceive = !(spiBuffer[LED_BITS] & 0x20);  // !RECV_BUSY
  }

  const bool isAvailableUartSendData = spiBuffer[LED_BITS] & 0x10;
  if (isAvailableUartSendData) {
    const uint8_t uartSendBytes = spiBuffer[UART_SEND_BYTES];
    Serial.print(static_cast<char>(uartSendBytes));
  }
#endif
}
