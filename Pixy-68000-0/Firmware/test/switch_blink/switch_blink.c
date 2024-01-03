
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;

#define F_CPU 20000000L

#define HIGH 1
#define LOW 0

#define PIN_SW0 0
#define PIN_SW1 1
#define PIN_SW2 2
#define PIN_SW3 3

#define PIN_LED0 4
#define PIN_LED1 5
#define PIN_LED2 6
#define PIN_LED3 7

static volatile uint8_t* const pSignal = (uint8_t*)0x00100001;

// Arduino like LED output.
static inline void digitalWrite(uint8_t pin, uint8_t val) {
    if (val) {
        *pSignal |= 0x01 << pin;
    } else {
        *pSignal &= ~(0x01 << pin);
    }
}

static inline int digitalRead(uint8_t pin) {
    return *pSignal & (0x01 << pin);
}

void main() {
    while (1) {
        digitalWrite(PIN_LED0, digitalRead(PIN_SW0));
        digitalWrite(PIN_LED1, digitalRead(PIN_SW1));
        digitalWrite(PIN_LED2, digitalRead(PIN_SW2));
        digitalWrite(PIN_LED3, digitalRead(PIN_SW3));
    }
}
