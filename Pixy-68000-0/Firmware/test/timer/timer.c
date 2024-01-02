#include <stdint.h>
#include <stdbool.h>

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

#define TIMER_ENABLE_INT 0x01

//---------------------------------------

#define __cli() { asm volatile ("oriw #0x0700,%%sr" : : : "memory"); } ((void)0)
#define __sti() { asm volatile ("andiw #0xf8ff,%%sr" : : : "memory"); } ((void)0)

//---------------------------------------

static volatile uint8_t* const pSignal = (uint8_t*)0x00100001;

static volatile uint8_t* const pTimerControl = (uint8_t*)0x00100009;
static const volatile uint16_t* const pTimerCount = (uint16_t*)0x0010000a;

//---------------------------------------

static inline void __digitalWrite(uint8_t pin, uint8_t val) {
    if (val) {
        *pSignal |= 0x01 << pin;
    } else {
        *pSignal &= ~(0x01 << pin);
    }
}

static inline void digitalWrite(uint8_t pin, uint8_t val) {
    __cli();
    __digitalWrite(pin, val);
    __sti();
}

static inline int digitalRead(uint8_t pin) {
    __cli();
    const uint8_t v = *pSignal & (0x01 << pin);
    __sti();
    return v ? HIGH : LOW;
}

//---------------------------------------

static inline uint16_t getFreeRunningCounter() {
    return *pTimerCount;
}

///////////////////////////////////////////////////////////////

static inline void enableInterrupts() {
    __cli();
    *pTimerControl |= TIMER_ENABLE_INT;
    __sti();
}

///////////////////////////////////////////////////////////////

__attribute__((interrupt_handler))
static void irq_handler_error() {
    __digitalWrite(PIN_LED2, HIGH);
}

static uint8_t count;

__attribute__((interrupt_handler))
static void irq_handler_timer_reached() {
    const uint16_t v = getFreeRunningCounter();
    count++;
    __digitalWrite(PIN_LED3, count >> 7);
}

__attribute__((used, section(".vectors")))
void (* const vectors[])(void) =
{
    irq_handler_error,      // 2 : Bus error
    irq_handler_error,      // 3 : Address error
    irq_handler_error,      // 4 : Invalid instruction
    irq_handler_error,      // 5 : Zero divide error
    irq_handler_error,      // 6 : CHK
    irq_handler_error,      // 7 : TRAPV
    irq_handler_error,      // 8 : Privilege vioration 
    irq_handler_error,      // 9 : Trace
    irq_handler_error,      // 10: Line 1010
    irq_handler_error,      // 11: Line 1111
    irq_handler_error,      // 12: (Reserved)
    irq_handler_error,      // 13: (Reserved)
    irq_handler_error,      // 14: (Reserved)
    irq_handler_error,      // 15: (Reserved)
    irq_handler_error,      // 16: (Reserved)
    irq_handler_error,      // 17: (Reserved)
    irq_handler_error,      // 18: (Reserved)
    irq_handler_error,      // 19: (Reserved)
    irq_handler_error,      // 20: (Reserved)
    irq_handler_error,      // 21: (Reserved)
    irq_handler_error,      // 22: (Reserved)
    irq_handler_error,      // 23: (Reserved)
    irq_handler_error,      // 24: Sprious interrupt
    irq_handler_timer_reached,    // 25: Level 1 interrupt autovector (Timer 1kHz)
    irq_handler_error,      // 26: Level 2 interrupt autovector (UART sent)
    irq_handler_error,      // 27: Level 3 interrupt autovector (UART received)
    irq_handler_error,      // 28: Level 4 interrupt autovector
    irq_handler_error,      // 29: Level 5 interrupt autovector
    irq_handler_error,      // 30: Level 6 interrupt autovector
    irq_handler_error,      // 31: Level 7 interrupt autovector
};

///////////////////////////////////////////////////////////////

void main() {
    enableInterrupts();

    while (1) {
        digitalWrite(PIN_LED0, digitalRead(PIN_SW0));
        digitalWrite(PIN_LED1, digitalRead(PIN_SW1));
    }
}
