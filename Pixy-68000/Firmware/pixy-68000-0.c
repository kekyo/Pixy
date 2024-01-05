#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>

#define RECEIVE_BUFFER 256
#define SEND_BUFFER 256

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

static uint8_t receiveBuffer[RECEIVE_BUFFER];
static volatile uint8_t receiveWritePointer = 0;
static volatile uint8_t receiveReadPointer = 0;

static uint8_t sendBuffer[SEND_BUFFER];
static volatile uint8_t sendWritePointer = 0;
static volatile uint8_t sendReadPointer = 0;

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

static inline bool isReceived() {
    __cli();
    const bool v = receiveWritePointer != receiveReadPointer;
    __sti();
    return v;
}

static uint8_t recv() {
    while (!isReceived());
    const uint8_t p = receiveReadPointer;
    const uint8_t v = receiveBuffer[p];
    receiveReadPointer++;
    return v;
}

static inline bool __canSend() {
    const uint8_t pw = sendWritePointer + 1;
    const bool v = pw != sendReadPointer;
    return v;
}

static inline void __send(uint8_t ch) {
    const uint8_t p = sendWritePointer;
    sendBuffer[p] = ch;
    sendWritePointer++;
    if (p == sendReadPointer) {
        *pUartControl |= UART_ENABLE_SEND_INT;
    }
}

void send(uint8_t ch) {
    while (1) {
        __cli();
        if (__canSend()) {
            __send(ch);
            __sti();
            break;
        }
        __sti();
    }
}

void print(const char *pStr) {
    while (*pStr != '\0') {
        send((uint8_t)*pStr);
        pStr++;
    }
}

void println(const char *pStr) {
    while (*pStr != '\0') {
        send((uint8_t)*pStr);
        pStr++;
    }
    send('\r');
    send('\n');
}

//---------------------------------------

static inline uint16_t getFreeRunningCounter() {
    return *pTimerCount;
}

///////////////////////////////////////////////////////////////

static uint8_t errorCode = 0;

static void __irq_handler_error(uint8_t code) {
    errorCode = code;
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

// TODO:
static uint8_t count;
__attribute__((interrupt_handler))
static void irq_handler_timer_reached() {
    const uint16_t v = getFreeRunningCounter();
    count++;
}

__attribute__((interrupt_handler))
static void irq_handler_uart_received() {
    const uint8_t p = receiveWritePointer;
    receiveBuffer[p] = *pUartReceiveData;
    receiveWritePointer++;
}

__attribute__((interrupt_handler))
static void irq_handler_uart_sent() {
    const uint8_t p = sendReadPointer;
    if (p == sendWritePointer) {
        *pUartControl &= ~UART_ENABLE_SEND_INT;
    } else {
        *pUartSendData = sendBuffer[p];
        sendReadPointer++;
    }
}

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
    irq_handler_timer_reached,    // 25: Level 1 interrupt autovector (Timer 1kHz)
    irq_handler_uart_sent,        // 26: Level 2 interrupt autovector (UART sent)
    irq_handler_uart_received,    // 27: Level 3 interrupt autovector (UART received)
    irq_handler_error28,          // 28: Level 4 interrupt autovector
    irq_handler_error29,          // 29: Level 5 interrupt autovector
    irq_handler_error30,          // 30: Level 6 interrupt autovector
    irq_handler_error31,          // 31: Level 7 interrupt autovector
};

///////////////////////////////////////////////////////////////

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
    //*pTimerControl |= TIMER_ENABLE_INT;

    __sti();
}

void _exit(int v) {
    while (1) {
        asm volatile ("stop #0x2700" : : : "memory");
    }
}

void *sbrk (ptrdiff_t incr) {
    return 0;
}

ssize_t read(int fd, void *buf, size_t count) {
    return 0;
}

ssize_t write (int fd, const void *buf, size_t count) {
    return -1;
}

off_t lseek (int fd, off_t offset, int whence) {
    return -1;
}

int close (int fd) {
    return 0;
}
