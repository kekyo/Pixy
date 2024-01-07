#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <pixy-68000.h>

int count = 0;
bool state = false;

char buffer[40];

void main() {
    while (1) {
#if 1
        int v;
        scanf("%d", &v);
        printf("Value=%d\r\n", v);
#else
        if (!state) {
            if (digitalRead(PIN_SW0)) {
                printf("COUNT=%d\r\n", count++);
                state = true;
            }
        } else if (!digitalRead(PIN_SW0)) {
            state = false;
        }
        digitalWrite(PIN_LED1, digitalRead(PIN_SW1));
        digitalWrite(PIN_LED2, digitalRead(PIN_SW2));
        digitalWrite(PIN_LED3, digitalRead(PIN_SW3));
#endif
    }
}
