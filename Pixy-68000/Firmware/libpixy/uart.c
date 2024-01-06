#include "internal.h"

#define RECEIVE_BUFFER 256
#define SEND_BUFFER 256

static uint8_t receiveBuffer[RECEIVE_BUFFER];
static volatile uint8_t receiveWritePointer = 0;
static volatile uint8_t receiveReadPointer = 0;

static uint8_t sendBuffer[SEND_BUFFER];
static volatile uint8_t sendWritePointer = 0;
static volatile uint8_t sendReadPointer = 0;

bool __havebyte() {
    return receiveWritePointer != receiveReadPointer;
}

bool havebyte() {
    return receiveWritePointer != receiveReadPointer;
}

uint8_t __inbyte() {
    const uint8_t v = receiveBuffer[receiveReadPointer];
    receiveReadPointer++;
    return v;
}

uint8_t inbyte() {
    while (!__havebyte());
    return __inbyte();
}

static inline bool __senderIsEmpty() {
    return sendWritePointer == sendReadPointer;
}

static inline bool __canSend() {
    const uint8_t pw = sendWritePointer + 1;
    return pw != sendReadPointer;
}

bool canSend() {
    __cli();
    const bool v = __canSend();
    __sti();
    return v;
}

static inline void __outbyte(uint8_t ch) {
    const uint8_t p = sendWritePointer;
    sendBuffer[p] = ch;
    sendWritePointer++;
    if (p == sendReadPointer) {
        *pUartControl |= UART_ENABLE_SEND_INT;
    }
}

void outbyte(uint8_t ch) {
    while (1) {
        __cli();
        if (__canSend()) {
            __outbyte(ch);
            __sti();
            break;
        }
        __sti();
    }
}

void print(const char *pStr) {
    while (*pStr != '\0') {
        outbyte((uint8_t)*pStr);
        pStr++;
    }
}

void println(const char *pStr) {
    while (*pStr != '\0') {
        outbyte((uint8_t)*pStr);
        pStr++;
    }
    outbyte('\r');
    outbyte('\n');
}

__attribute__((interrupt_handler))
void __irq_handler_uart_received() {
    const uint8_t p = receiveWritePointer;
    receiveBuffer[p] = *pUartReceiveData;
    receiveWritePointer++;
}

__attribute__((interrupt_handler))
void __irq_handler_uart_sent() {
    const uint8_t p = sendReadPointer;
    if (p == sendWritePointer) {
        *pUartControl &= ~UART_ENABLE_SEND_INT;
    } else {
        *pUartSendData = sendBuffer[p];
        sendReadPointer++;
    }
}
