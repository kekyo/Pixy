// SRAM overall area read/write tester.

typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;

static volatile uint8_t* const pOutputSignal = (uint8_t*)0x00100001;
static const uint32_t length = 0x00100000;
static void* pRamStart = (void*)0x00000000;

void main() {
    uint8_t outputSignal = 0x06;  // yellow,green
    *pOutputSignal = outputSignal;

    // Read and write all bit patterns to all SRAM areas.
    volatile uint8_t* pTarget = pRamStart;
    for (uint32_t i = 0; i < length; i++, pTarget++) {

        // Clear overall.
        volatile uint8_t* pRamC = pRamStart;
        for (uint32_t j = 0; j < length / 2; j++, pRamC += 2) {
            *(volatile uint16_t*)pRamC = 0x0000;
        }

        outputSignal ^= 0x02;  // yellow
        *pOutputSignal = outputSignal;

        // Check overall cleanes.
        pRamC = pRamStart;
        for (uint32_t j = 0; j < length / 2; j++, pRamC += 2) {
            const uint16_t v2 = *(volatile uint16_t*)pRamC;
            if (v2 != 0x0000) {
                outputSignal &= ~0x04;  // ~green
                outputSignal |= 0x01;   // red
                *pOutputSignal = outputSignal;
            }
        }

        outputSignal ^= 0x02;  // yellow
        *pOutputSignal = outputSignal;

        for (uint16_t v = 0x0001; v < 0x0100; v <<= 1) {
            // Write a byte.
            *pTarget = (uint8_t)v;

            // Read a byte and comparing.
            if (*pTarget != (uint8_t)v) {
                outputSignal &= ~0x04;  // ~green
                outputSignal |= 0x01;   // red
                *pOutputSignal = outputSignal;
            }

            // Check.
            pRamC = pRamStart;
            for (uint32_t j = 0; j < length / 2; j++, pRamC += 2) {
                const uint16_t v2 = *(volatile uint16_t*)pRamC;
                if (v2 != 0x0000) {
                    if (((void*)pRamC == (void*)pTarget) &&
                        ((uint8_t)(v2 >> 8) == (uint8_t)v)) {
                    } else if (((void*)(pRamC + 1) == (void*)pTarget) &&
                        ((uint8_t)v2 == (uint8_t)v)) {
                    } else {
                        outputSignal &= ~0x04;  // ~green
                        outputSignal |= 0x01;   // red
                        *pOutputSignal = outputSignal;
                    }
                }
            }

            outputSignal ^= 0x02;  // yellow
            *pOutputSignal = outputSignal;
        }
    }

    outputSignal &= ~0x02;  // ~yellow
    outputSignal |= (outputSignal & 0x04) ? 0x08 : 0x00;  // blue when passed
    *pOutputSignal = outputSignal;

    // Stop.
    while (1);
}
