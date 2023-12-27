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

static volatile uint8_t* const pSignal = (uint8_t*)0x00100001;
static const volatile uint8_t* const pUartControl = (uint8_t*)0x00100003;
static volatile uint8_t* const pUartSendData = (uint8_t*)0x00100005;
static const volatile uint8_t* const pUartReceiveData = (uint8_t*)0x00100007;

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
    return *pUartControl & UART_SEND_BUSY;
}

static inline void send(uint8_t ch) {
    while (isSendBusy());
    *pUartSendData = ch;
}

static inline bool isReceived() {
    return *pUartControl & UART_RECEIVED;
}

static inline uint8_t recv() {
    while (!isReceived());
    return *pUartReceiveData;
}

static void println(const char *pStr) {
    while (*pStr != '\0') {
        send((uint8_t)*pStr);
        pStr++;
    }
    send('\r');
    send('\n');
}

static bool partialState = false;

void main() {
    while (1) {
        // Echo back
        if (isReceived()) {
            digitalWrite(PIN_LED0, HIGH);
            send(recv());
            digitalWrite(PIN_LED0, LOW);
        }

        // Trigger print by SW0.
        if (!partialState && digitalRead(PIN_SW0)) {
            // Print out
            digitalWrite(PIN_LED0, HIGH);
            println("Hello Pixy!");
            digitalWrite(PIN_LED0, LOW);
            partialState = true;
        } else if (partialState && !digitalRead(PIN_SW0)) {
            partialState = false;
        }
    }
}
