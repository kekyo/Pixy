#include "internal.h"

static inline void __digitalWrite(uint8_t pin, uint8_t val) {
    if (val) {
        *pSignal |= 0x01 << pin;
    } else {
        *pSignal &= ~(0x01 << pin);
    }
}

void digitalWrite(uint8_t pin, uint8_t val) {
    __cli();
    __digitalWrite(pin, val);
    __sti();
}

int digitalRead(uint8_t pin) {
    __cli();
    const uint8_t v = *pSignal & (0x01 << pin);
    __sti();
    return v ? HIGH : LOW;
}
