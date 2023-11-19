#include <Arduino.h>
#include <avr/io.h>

// Pin declaration for Pixy-mega128-sdram-hat

#define SDRAM_DQ0 PIN_PF0   // PF
#define SDRAM_DQ1 PIN_PF1
#define SDRAM_DQ2 PIN_PF2
#define SDRAM_DQ3 PIN_PF3
#define SDRAM_DQ4 PIN_PF4
#define SDRAM_DQ5 PIN_PF5
#define SDRAM_DQ6 PIN_PF6
#define SDRAM_DQ7 PIN_PF7

#define SDRAM_DQ8 PIN_PA0   // PA
#define SDRAM_DQ9 PIN_PA1
#define SDRAM_DQ10 PIN_PA2
#define SDRAM_DQ11 PIN_PA3
#define SDRAM_DQ12 PIN_PA4
#define SDRAM_DQ13 PIN_PA5
#define SDRAM_DQ14 PIN_PA6
#define SDRAM_DQ15 PIN_PA7

#define SDRAM_LDQM PIN_PE6
#define SDRAM_UDQM PIN_PE7

#define SDRAM_WE PIN_PB4
#define SDRAM_CAS PIN_PB5
#define SDRAM_RAS PIN_PB6
#define SDRAM_CS PIN_PB7

#define SDRAM_CKE PIN_PC6
#define SDRAM_CLK PIN_PC7

#define SDRAM_BA0 PIN_PC4
#define SDRAM_BA1 PIN_PC5

#define SDRAM_A0 PIN_PD0    // PD
#define SDRAM_A1 PIN_PD1
#define SDRAM_A2 PIN_PD2
#define SDRAM_A3 PIN_PD3
#define SDRAM_A4 PIN_PD4
#define SDRAM_A5 PIN_PD5
#define SDRAM_A6 PIN_PD6
#define SDRAM_A7 PIN_PD7
#define SDRAM_A8 PIN_PC0    // PC
#define SDRAM_A9 PIN_PC1
#define SDRAM_A10 PIN_PC2
#define SDRAM_A11 PIN_PC3

static void set_DQ_mode(bool isOutput) {
  PORTF = 0x00;
  PORTA = 0x00;
  if (isOutput) {
    DDRF = 0xff;   // PF: DQ0 - DQ7
    DDRA = 0xff;   // PA: DQ8 - DQ15
  } else {
    DDRF = 0x00;   // PF: DQ0 - DQ7
    DDRA = 0x00;   // PA: DQ8 - DQ15
  }
}

void setup() {
  Serial.begin(115200);
  Serial.println("setup()");

  set_DQ_mode(false);

  // Set all pins as output
  PORTD = 0x00;
  PORTC = 0x00;
  DDRD = 0xff;   // PD: A0 - A7
  DDRC = 0xff;   // PC: A8 - A11, BA0, BA1, CKE, CLK

  //DDRB = 0xf0;   // PB: WE, CAS, RAS, CS
  digitalWrite(SDRAM_WE, HIGH);
  digitalWrite(SDRAM_CAS, HIGH);
  digitalWrite(SDRAM_RAS, HIGH);
  digitalWrite(SDRAM_CS, HIGH);
  pinMode(SDRAM_WE, OUTPUT);
  pinMode(SDRAM_CAS, OUTPUT);
  pinMode(SDRAM_RAS, OUTPUT);
  pinMode(SDRAM_CS, OUTPUT);

  //DDRE = 0xc0;   // PE: LDQM, UDQM
  digitalWrite(SDRAM_LDQM, HIGH);
  digitalWrite(SDRAM_UDQM, HIGH);
  pinMode(SDRAM_LDQM, OUTPUT);
  pinMode(SDRAM_UDQM, OUTPUT);
}

void loop() {

}
