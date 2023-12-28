#include <stdint.h>
#include <stdbool.h>

#define RECEIVE_BUFFER 256

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

static uint8_t receiveBuffer[RECEIVE_BUFFER];
static uint16_t receiveWritePointer = 0;
static uint16_t receiveReadPointer = 0;

extern void cli();
extern void sti();

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
    return receiveWritePointer != receiveReadPointer;
}

static inline uint8_t recv() {
    while (!isReceived());
    const uint8_t rv = receiveBuffer[receiveReadPointer++];
    if (receiveReadPointer >= sizeof receiveBuffer) {
        receiveReadPointer = 0;
    }
    return rv;
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
            digitalWrite(PIN_LED3, HIGH);
            send(recv());
            digitalWrite(PIN_LED3, LOW);
        }

        // Trigger print by SW0.
        if (!partialState && digitalRead(PIN_SW0)) {
            // Print out
            digitalWrite(PIN_LED3, HIGH);
            println("Hello Pixy!");
            digitalWrite(PIN_LED3, LOW);
            partialState = true;
        } else if (partialState && !digitalRead(PIN_SW0)) {
            partialState = false;
        }
    }
}

//-------------------------------------------------------------

__attribute__((interrupt_handler))
static void irq_handler_bus_error() {
    digitalWrite(PIN_LED0, HIGH);
}

__attribute__((interrupt_handler))
static void irq_handler_address_error() {
    digitalWrite(PIN_LED1, HIGH);
}

__attribute__((interrupt_handler))
static void irq_handler_invalid_instruction() {
    digitalWrite(PIN_LED1, HIGH);
}

__attribute__((interrupt_handler))
static void irq_handler_interrupt_level1() {
    const uint8_t rv = *pUartReceiveData;
    receiveBuffer[receiveWritePointer++] = rv;
    if (receiveWritePointer >= sizeof receiveBuffer) {
        receiveWritePointer = 0;
    }
}

__attribute__ ((used, section(".vectors")))
void (* const vectors[])(void) =
{
    irq_handler_bus_error,                // 2 : Bus error
    irq_handler_address_error,            // 3 : Address error
    irq_handler_invalid_instruction,      // 4 : Invalid instruction
    irq_handler_invalid_instruction,      // 5 : Zero divide error
    irq_handler_invalid_instruction,      // 6 : CHK
    irq_handler_invalid_instruction,      // 7 : TRAPV
    irq_handler_invalid_instruction,      // 8 : Privilege vioration 
    irq_handler_invalid_instruction,      // 9 : Trace
    irq_handler_invalid_instruction,      // 10: Line 1010
    irq_handler_invalid_instruction,      // 11: Line 1111
    irq_handler_invalid_instruction,      // 12: (Reserved)
    irq_handler_invalid_instruction,      // 13: (Reserved)
    irq_handler_invalid_instruction,      // 14: (Reserved)
    irq_handler_invalid_instruction,      // 15: (Reserved)
    irq_handler_invalid_instruction,      // 16: (Reserved)
    irq_handler_invalid_instruction,      // 17: (Reserved)
    irq_handler_invalid_instruction,      // 18: (Reserved)
    irq_handler_invalid_instruction,      // 19: (Reserved)
    irq_handler_invalid_instruction,      // 20: (Reserved)
    irq_handler_invalid_instruction,      // 21: (Reserved)
    irq_handler_invalid_instruction,      // 22: (Reserved)
    irq_handler_invalid_instruction,      // 23: (Reserved)
    irq_handler_invalid_instruction,      // 24: Sprious interrupt
    irq_handler_interrupt_level1,         // 25: Level 1 interrupt autovector
    irq_handler_invalid_instruction,      // 26: Level 2 interrupt autovector
    irq_handler_invalid_instruction,      // 26: Level 3 interrupt autovector
    irq_handler_invalid_instruction,      // 27: Level 4 interrupt autovector
    irq_handler_invalid_instruction,      // 28: Level 5 interrupt autovector
    irq_handler_invalid_instruction,      // 29: Level 6 interrupt autovector
    irq_handler_invalid_instruction,      // 30: Level 7 interrupt autovector
};
