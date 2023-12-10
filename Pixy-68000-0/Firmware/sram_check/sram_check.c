// SRAM overall area read/write tester.

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;

static volatile uint8_t* const pOutputSignal = (uint8_t*)0x00100001;
static const uint32_t length = 0x00100000;

void main() {
    uint8_t* pRamStart = (uint8_t*)0x00000000;

    uint8_t outputSignal = 0x06;  // yellow,green
    *pOutputSignal = outputSignal;

    // Read and write all bit patterns to all SRAM areas.
    for (uint16_t base = 0; base < 0x100; base++) {
        volatile uint8_t* pRam = pRamStart;

        for (uint32_t i = 0; i < length; i++, pRam++) {
            const uint8_t v = (uint8_t)(i + base);

            // Write a byte.
            *pRam = v;

            // Read a byte and comparing.
            if (*pRam != v) {
                outputSignal &= ~0x04;  // ~green
                outputSignal |= 0x01;   // red
                *pOutputSignal = outputSignal;
            }
        }

        outputSignal ^= 0x02;  // yellow
        *pOutputSignal = outputSignal;
    }

    outputSignal &= ~0x02;  // ~yellow
    outputSignal |= (outputSignal & 0x04) ? 0x08 : 0x00;  // blue when passed
    *pOutputSignal = outputSignal;

    // Stop.
    while (1);
}
