// SRAM overall area read/write tester.

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;

#define HIGH 1
#define LOW 0

#define PIN_LED0 4
#define PIN_LED1 5
#define PIN_LED2 6
#define PIN_LED3 7

static volatile uint8_t* const pSignal = (uint8_t*)0x00100001;
static const uint32_t length = 0x00100000;

static inline void __digitalWrite(uint8_t pin, uint8_t val) {
    if (val) {
        *pSignal |= 0x01 << pin;
    } else {
        *pSignal &= ~(0x01 << pin);
    }
}

static inline int __digitalRead(uint8_t pin) {
    return *pSignal & (0x01 << pin);
}

void main() {
    volatile uint8_t* pRamStart = (uint8_t*)0x00000000;

    __digitalWrite(PIN_LED1, HIGH);  // yellow
    __digitalWrite(PIN_LED2, HIGH);  // green

    // Read and write all bit patterns to all SRAM areas.
    for (uint8_t i = 0; i < 8; i++) {
        volatile uint8_t* pRam = pRamStart;
        const uint8_t v = (uint8_t)(0x01 << i);

        for (uint32_t j = 0x00000000; j < 0x00100000; j++, pRam++) {
            // Intiialize.
            *pRam = 0x00;

            // Write a byte.
            *pRam = v;

            // Read a byte and comparing.
            if (*pRam != v) {
                __digitalWrite(PIN_LED2, LOW);    // ~green
                __digitalWrite(PIN_LED0, HIGH);   // red
            }

            // Finalize.
            *pRam = 0x00;
        }

        __digitalWrite(PIN_LED1, __digitalRead(PIN_LED1) ? LOW : HIGH);
    }

    __digitalWrite(PIN_LED1, LOW);  // ~yellow
    __digitalWrite(PIN_LED3,  __digitalRead(PIN_LED2));   // blue when passed

    // Stop.
    while (1);
}
