#include "internal.h"

static volatile uint8_t errorCode = 0;

__attribute__((noreturn))
static inline void __irq_handler_error(uint8_t code) {
    while (1) {
        errorCode = code;
    }
}

#define IRQ_ERROR_HANDLER(code) \
    __attribute__((interrupt_handler)) \
    static void irq_handler_error##code() { \
        __irq_handler_error(code); \
    }

IRQ_ERROR_HANDLER(2)
IRQ_ERROR_HANDLER(3)
IRQ_ERROR_HANDLER(4)
IRQ_ERROR_HANDLER(5)
IRQ_ERROR_HANDLER(6)
IRQ_ERROR_HANDLER(7)
IRQ_ERROR_HANDLER(8)
IRQ_ERROR_HANDLER(9)
IRQ_ERROR_HANDLER(10)
IRQ_ERROR_HANDLER(11)
IRQ_ERROR_HANDLER(12)
IRQ_ERROR_HANDLER(13)
IRQ_ERROR_HANDLER(14)
IRQ_ERROR_HANDLER(15)
IRQ_ERROR_HANDLER(16)
IRQ_ERROR_HANDLER(17)
IRQ_ERROR_HANDLER(18)
IRQ_ERROR_HANDLER(19)
IRQ_ERROR_HANDLER(20)
IRQ_ERROR_HANDLER(21)
IRQ_ERROR_HANDLER(22)
IRQ_ERROR_HANDLER(23)
IRQ_ERROR_HANDLER(24)
IRQ_ERROR_HANDLER(28)
IRQ_ERROR_HANDLER(29)
IRQ_ERROR_HANDLER(30)
IRQ_ERROR_HANDLER(31)

extern void __irq_handler_timer_reached();
extern void __irq_handler_uart_sent();
extern void __irq_handler_uart_received();

__attribute__((used, section(".vectors")))
void (* const vectors[])(void) =
{
    irq_handler_error2,           // 2 : Bus error
    irq_handler_error3,           // 3 : Address error
    irq_handler_error4,           // 4 : Invalid instruction
    irq_handler_error5,           // 5 : Zero divide error
    irq_handler_error6,           // 6 : CHK
    irq_handler_error7,           // 7 : TRAPV
    irq_handler_error8,           // 8 : Privilege vioration 
    irq_handler_error9,           // 9 : Trace
    irq_handler_error10,          // 10: Line 1010
    irq_handler_error11,          // 11: Line 1111
    irq_handler_error12,          // 12: (Reserved)
    irq_handler_error13,          // 13: (Reserved)
    irq_handler_error14,          // 14: (Reserved)
    irq_handler_error15,          // 15: (Reserved)
    irq_handler_error16,          // 16: (Reserved)
    irq_handler_error17,          // 17: (Reserved)
    irq_handler_error18,          // 18: (Reserved)
    irq_handler_error19,          // 19: (Reserved)
    irq_handler_error20,          // 20: (Reserved)
    irq_handler_error21,          // 21: (Reserved)
    irq_handler_error22,          // 22: (Reserved)
    irq_handler_error23,          // 23: (Reserved)
    irq_handler_error24,          // 24: Sprious interrupt
    __irq_handler_timer_reached,  // 25: Level 1 interrupt autovector (Timer 1kHz)
    __irq_handler_uart_sent,      // 26: Level 2 interrupt autovector (UART sent)
    __irq_handler_uart_received,  // 27: Level 3 interrupt autovector (UART received)
    irq_handler_error28,          // 28: Level 4 interrupt autovector
    irq_handler_error29,          // 29: Level 5 interrupt autovector
    irq_handler_error30,          // 30: Level 6 interrupt autovector
    irq_handler_error31,          // 31: Level 7 interrupt autovector
};

extern const uint8_t __rom_top;
extern const uint8_t __rom_data_top;
extern const uint32_t __init_vec[0x100];
extern uint32_t __vec[0x100];
extern uint8_t _sdata;
extern uint8_t _edata;
extern uint8_t __bss_start;
extern uint8_t __end;

void hardware_init_hook() {
    // Copy initial vectors.
    memcpy(__vec, __init_vec, sizeof __init_vec);

    // Copy initial .data section.
    memcpy(&_sdata, &__rom_data_top, &_edata - &_sdata);

    // Clear .bss section.
    memset(&__bss_start, 0, &__end - &__bss_start);

    *pUartControl &= ~UART_ENABLE_SEND_INT;
    *pUartControl |= UART_ENABLE_RECEIVE_INT;
    *pTimerControl |= TIMER_ENABLE_INT;

    __sti();
}
