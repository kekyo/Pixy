typedef unsigned char uint8_t;

void main() {
    volatile uint8_t* pOutputSignal = (uint8_t*)0x00100001;
    uint8_t count = 0x01;
    while (1) {
        *pOutputSignal = count;
        count <<= 1;
        if (count >= 0x10) {
            count = 0x01;
        }
    }
}
