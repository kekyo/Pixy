#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>

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

extern void digitalWrite(uint8_t pin, uint8_t val);
extern int digitalRead(uint8_t pin);
extern void println(const char *pStr);

int count = 123;
bool state = false;

void main() {
    while (1) {
        if (!state) {
            if (digitalRead(PIN_SW0)) {
                char buffer[20];
                sprintf(buffer, "COUNT=%d", count++);
                println(buffer);
                state = true;
            }
        } else if (!digitalRead(PIN_SW0)) {
            state = false;
        }
        digitalWrite(PIN_LED1, digitalRead(PIN_SW1));
        digitalWrite(PIN_LED2, digitalRead(PIN_SW2));
        digitalWrite(PIN_LED3, digitalRead(PIN_SW3));
    }
}
