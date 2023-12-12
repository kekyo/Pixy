
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;

#define F_CPU 20000000L

#define HIGH 1
#define LOW 0

#define PIN_LED0 0
#define PIN_LED1 1
#define PIN_LED2 2
#define PIN_LED3 3

#define PIN_SW0 4
#define PIN_SW1 5
#define PIN_SW2 6
#define PIN_SW3 7

static volatile uint8_t* const pOutputSignal = (uint8_t*)0x00100001;
static const volatile uint8_t* const pInputSignal = (uint8_t*)0x00100003;

// Arduino like LED output.
static inline void digitalWrite(uint8_t pin, uint8_t val) {
    switch (pin) {
        case PIN_LED0:
        case PIN_LED1:
        case PIN_LED2:
        case PIN_LED3:
            if (val) {
                *pOutputSignal |= 0x01 << (pin - PIN_LED0);
            } else {
                *pOutputSignal &= ~(0x01 << (pin - PIN_LED0));
            }
            break;
    }
}

static inline int digitalRead(uint8_t pin) {
    switch (pin) {
        case PIN_LED0:
        case PIN_LED1:
        case PIN_LED2:
        case PIN_LED3:
            return *pOutputSignal & (0x01 << (pin - PIN_LED0));
        case PIN_SW0:
        case PIN_SW1:
        case PIN_SW2:
        case PIN_SW3:
            return *pInputSignal & (0x01 << (pin - PIN_SW0));
        default:
            return LOW;
    }
}

void main() {
    while (1) {
        digitalWrite(PIN_LED0, digitalRead(PIN_SW0));
        digitalWrite(PIN_LED1, digitalRead(PIN_SW1));
        digitalWrite(PIN_LED2, digitalRead(PIN_SW2));
        digitalWrite(PIN_LED3, digitalRead(PIN_SW3));
    }
}
