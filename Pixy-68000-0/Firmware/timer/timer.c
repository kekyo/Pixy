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

#define UART_SEND_BUSY 0x01
#define UART_RECEIVED 0x02
#define UART_ENABLE_SEND_INT 0x04
#define UART_ENABLE_RECEIVE_INT 0x08

#define TIMER_ENABLE_INT 0x01
#define TIMER_REACHED 0x02

//---------------------------------------

#define __cli() { asm volatile ("oriw #0x0700,%%sr" : : : "memory"); } ((void)0)
#define __sti() { asm volatile ("andiw #0xf8ff,%%sr" : : : "memory"); } ((void)0)

//---------------------------------------

static volatile uint8_t* const pSignal = (uint8_t*)0x00100001;
static volatile uint8_t* const pUartControl = (uint8_t*)0x00100003;
static volatile uint8_t* const pUartSendData = (uint8_t*)0x00100005;
static const volatile uint8_t* const pUartReceiveData = (uint8_t*)0x00100007;

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
    *pTimerControl &= ~TIMER_REACHED;
    *pTimerControl |= TIMER_ENABLE_INT;
    __sti();
}

///////////////////////////////////////////////////////////////

__attribute__((interrupt_handler))
static void irq_handler_bus_error() {
    __digitalWrite(PIN_LED0, HIGH);
}

__attribute__((interrupt_handler))
static void irq_handler_address_error() {
    __digitalWrite(PIN_LED1, HIGH);
}

static void irq_handler_error() {
    __digitalWrite(PIN_LED2, HIGH);
}

static void __irq_handler_error(uint8_t code) {
    __digitalWrite(PIN_LED3, HIGH);
}

#define IRQ_ERROR_HANDLER(code) \
    __attribute__((interrupt_handler)) \
    static void irq_handler_error##code() { \
        __irq_handler_error(code); \
    }

IRQ_ERROR_HANDLER(4)
IRQ_ERROR_HANDLER(5)
IRQ_ERROR_HANDLER(6)
IRQ_ERROR_HANDLER(7)
IRQ_ERROR_HANDLER(8)
IRQ_ERROR_HANDLER(9)
IRQ_ERROR_HANDLER(10)
IRQ_ERROR_HANDLER(11)
IRQ_ERROR_HANDLER(24)
IRQ_ERROR_HANDLER(26)
IRQ_ERROR_HANDLER(27)
IRQ_ERROR_HANDLER(28)
IRQ_ERROR_HANDLER(29)
IRQ_ERROR_HANDLER(30)
IRQ_ERROR_HANDLER(31)

static uint8_t count;

__attribute__((interrupt_handler))
static void irq_handler_timer_reached() {
    const uint16_t v = *pTimerCount;
    count++;
    __digitalWrite(PIN_LED3, count >> 7);
}

__attribute__((used, section(".vectors")))
void (* const vectors[])(void) =
{
    irq_handler_bus_error,        // 2 : Bus error
    irq_handler_address_error,    // 3 : Address error
    irq_handler_error4,     // 4 : Invalid instruction
    irq_handler_error5,     // 5 : Zero divide error
    irq_handler_error6,     // 6 : CHK
    irq_handler_error7,     // 7 : TRAPV
    irq_handler_error8,     // 8 : Privilege vioration 
    irq_handler_error9,     // 9 : Trace
    irq_handler_error10,    // 10: Line 1010
    irq_handler_error11,    // 11: Line 1111
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
    irq_handler_error24,    // 24: Sprious interrupt
    irq_handler_timer_reached,    // 25: Level 1 interrupt autovector (Timer 1kHz)
    irq_handler_error26,          // 26: Level 2 interrupt autovector (UART sent)
    irq_handler_error27,          // 27: Level 3 interrupt autovector (UART received)
    irq_handler_error28,          // 28: Level 4 interrupt autovector
    irq_handler_error29,          // 29: Level 5 interrupt autovector
    irq_handler_error30,          // 30: Level 6 interrupt autovector
    irq_handler_error31,          // 31: Level 7 interrupt autovector
};

///////////////////////////////////////////////////////////////

void main() {
    void** pv = (void**)0x00000008;
    pv[23] = irq_handler_timer_reached;
    enableInterrupts();
    while (1) {
    }
}
