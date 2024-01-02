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

static volatile uint8_t* const pSignal = (uint8_t*)0x00100001;
static const volatile uint8_t* const pUartStatus = (uint8_t*)0x00100003;
static volatile uint8_t* const pUartSendByte = (uint8_t*)0x00100005;

static inline void digitalWrite(uint8_t pin, uint8_t val) {
    if (val) {
        *pSignal |= 0x01 << pin;
    } else {
        *pSignal &= ~(0x01 << pin);
    }
}

static inline int digitalRead(uint8_t pin) {
    return *pSignal & (0x01 << pin);
}

static inline bool isSendBusy() {
    return *pUartStatus & UART_SEND_BUSY;
}

static inline void send(uint8_t ch) {
    while (isSendBusy());
    *pUartSendByte = ch;
}

static void println(const char *pStr) {
    while (*pStr != '\0') {
        send((uint8_t)*pStr);
        pStr++;
    }
    send('\n');
}

void main() {
    while (1) {
        if (digitalRead(PIN_SW0)) {
            println("Hello Pixy!");
        }
        digitalWrite(PIN_LED1, digitalRead(PIN_SW1));
        digitalWrite(PIN_LED2, digitalRead(PIN_SW2));
        digitalWrite(PIN_LED3, digitalRead(PIN_SW3));
    }
}
