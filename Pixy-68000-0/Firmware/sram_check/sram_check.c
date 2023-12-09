typedef unsigned char uint8_t;
typedef unsigned long uint16_t;
typedef unsigned long uint32_t;

void main() {
    volatile uint8_t* pOutputSignal = (uint8_t*)0x00100001;
    uint8_t* pRamStart = (uint8_t*)0x00000000;
    const uint32_t length = 0x00100000;

    uint8_t outputSignal = 0x02;  // yellow
    *pOutputSignal = outputSignal;
    for (uint16_t base = 0; base < 0x100; base++) {
        volatile uint8_t* pRam = pRamStart;
        for (uint32_t i = 0; i < length; i++) {
            uint8_t v = (uint8_t)(i + base);
            *pRam = v;
            if (*pRam != v) {
                outputSignal |= 0x01;  // red
                *pOutputSignal = outputSignal;
            }
            pRam++;
        }
    }
    outputSignal |= 0x04;  // green
    *pOutputSignal = outputSignal;

    while (1);
}
