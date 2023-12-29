#include <stdint.h>
#include <stdbool.h>

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
#define TIMER_REACHED 0x02

//---------------------------------------

extern void __cli();
extern void __sti();

//---------------------------------------

static volatile uint8_t* const pSignal = (uint8_t*)0x00100001;
static volatile uint8_t* const pUartControl = (uint8_t*)0x00100003;
static volatile uint8_t* const pUartSendData = (uint8_t*)0x00100005;
static const volatile uint8_t* const pUartReceiveData = (uint8_t*)0x00100007;

static volatile uint8_t* const pTimerControl = (uint8_t*)0x00100009;
static const volatile uint16_t* const pTimerCount = (uint16_t*)0x00100010;

//---------------------------------------

static uint8_t receiveBuffer[RECEIVE_BUFFER];
static uint16_t receiveWritePointer = 0;
static uint16_t receiveReadPointer = 0;

static uint8_t sendBuffer[SEND_BUFFER];
static uint16_t sendWritePointer = 0;
static uint16_t sendReadPointer = 0;

static inline void digitalWrite(uint8_t pin, uint8_t val) {
    // TODO: save IPL
    if (val) {
        *pSignal |= 0x01 << pin;
    } else {
        *pSignal &= ~(0x01 << pin);
    }
}

static inline int digitalRead(uint8_t pin) {
    return *pSignal & (0x01 << pin);
}

static inline void enableUartInterrupt() {
    __cli();
    *pUartControl &= ~UART_ENABLE_SEND_INT;
    *pUartControl |= UART_ENABLE_RECEIVE_INT;
    __sti();
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

static inline void __send(uint8_t ch) {
    if (sendWritePointer == sendReadPointer) {
        sendBuffer[sendWritePointer++] = ch;
        if (sendWritePointer >= sizeof sendBuffer) {
            sendWritePointer = 0;
        }
        *pUartControl |= UART_ENABLE_SEND_INT;
    }
    else
    {
        sendBuffer[sendWritePointer++] = ch;
        if (sendWritePointer >= sizeof sendBuffer) {
            sendWritePointer = 0;
        }
    }
}

static inline void send(uint8_t ch) {
    __cli();
    __send(ch);
    __sti();
}

static void print(const char *pStr) {
    __cli();
    while (*pStr != '\0') {
        __send((uint8_t)*pStr);
        pStr++;
    }
    __sti();
}

static void println(const char *pStr) {
    __cli();
    while (*pStr != '\0') {
        __send((uint8_t)*pStr);
        pStr++;
    }
    __send('\r');
    __send('\n');
    __sti();
}

//---------------------------------------

static inline void enableTimerInterrupt() {
    __cli();
    *pTimerControl &= ~TIMER_REACHED;
    *pTimerControl |= TIMER_ENABLE_INT;
    __sti();
}

static inline uint16_t getFreeRunningCounter() {
    return *pTimerCount;
}

///////////////////////////////////////////////////////////////

static bool partialState = false;

void main() {
    enableUartInterrupt();
    enableTimerInterrupt();

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

///////////////////////////////////////////////////////////////

__attribute__((interrupt_handler))
static void irq_handler_error() {
    digitalWrite(PIN_LED0, HIGH);
}

static uint8_t count;

__attribute__((interrupt_handler))
static void irq_handler_timer_reached() {
    *pTimerControl &= ~TIMER_REACHED;
    count++;
    digitalWrite(PIN_LED2, count >> 7);
}

__attribute__((interrupt_handler))
static void irq_handler_uart_received() {
    receiveBuffer[receiveWritePointer++] = *pUartReceiveData;
    if (receiveWritePointer >= sizeof receiveBuffer) {
        receiveWritePointer = 0;
    }
}

__attribute__((interrupt_handler))
static void irq_handler_uart_sent() {
    if (sendReadPointer == sendWritePointer) {
        *pUartControl &= ~UART_ENABLE_SEND_INT;
    } else {
        *pUartSendData = sendBuffer[sendReadPointer++];
        if (sendReadPointer >= sizeof sendBuffer) {
            sendReadPointer = 0;
        }
    }
}

__attribute__ ((used, section(".vectors")))
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
    irq_handler_uart_sent,        // 26: Level 2 interrupt autovector (UART sent)
    irq_handler_uart_received,    // 27: Level 3 interrupt autovector (UART received)
    irq_handler_error,            // 28: Level 4 interrupt autovector
    irq_handler_error,            // 29: Level 5 interrupt autovector
    irq_handler_error,            // 30: Level 6 interrupt autovector
    irq_handler_error,            // 31: Level 7 interrupt autovector
};
