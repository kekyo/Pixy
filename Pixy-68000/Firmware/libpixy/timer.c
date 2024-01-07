#include "internal.h"

static uint16_t lastCount;
static uint32_t runningCount;

__attribute__((interrupt_handler))
void __irq_handler_timer_reached() {
    const uint16_t count = *pTimerCount;
    const uint16_t differ = (count > lastCount) ?
        (count - lastCount) : (UINT16_MAX - lastCount + count);
    runningCount += differ;
}

uint32_t millis() {
    __cli();
    const uint32_t v = runningCount;
    __sti();
    return v;
}
