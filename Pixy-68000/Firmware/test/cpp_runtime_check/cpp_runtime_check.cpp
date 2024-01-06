#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <malloc.h>
#include <new>

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

extern "C" void digitalWrite(uint8_t pin, uint8_t val);
extern "C" int digitalRead(uint8_t pin);
extern "C" void println(const char *pStr);

class EffectBase
{
protected:
    EffectBase() {
    }

public:
    virtual ~EffectBase() {
    }

    virtual bool requirePrintCount() = 0;
    virtual void printMessage() = 0;
};

class Effect : public EffectBase
{
private:
    const char* name_;
    const uint8_t switchPin_;
    const uint8_t ledPin_;
    int count_;
    bool state_;

public:
    Effect(const char* name, uint8_t switchPin, uint8_t ledPin) :
        name_(name), switchPin_(switchPin), ledPin_(ledPin), count_(123), state_(false) {
    }

    virtual ~Effect();

    virtual bool requirePrintCount();
    virtual void printMessage();
};

int main() {
    EffectBase* ppEffects[4];
    ppEffects[0] = (EffectBase*)malloc(sizeof(Effect));
    ppEffects[1] = (EffectBase*)malloc(sizeof(Effect));
    ppEffects[2] = (EffectBase*)malloc(sizeof(Effect));
    ppEffects[3] = (EffectBase*)malloc(sizeof(Effect));
    new(ppEffects[0]) Effect("IO0", PIN_SW0, PIN_LED0);
    new(ppEffects[1]) Effect("IO1", PIN_SW1, PIN_LED1);
    new(ppEffects[2]) Effect("IO2", PIN_SW2, PIN_LED2);
    new(ppEffects[3]) Effect("IO3", PIN_SW3, PIN_LED3);

    while (1) {
        for (int i = 0; i < 4; i++) {
            if (ppEffects[i]->requirePrintCount()) {
                ppEffects[i]->printMessage();
            }
        }
    }
}

Effect::~Effect() {
}

bool Effect::requirePrintCount() {
    if (!state_) {
        if (digitalRead(switchPin_)) {
            digitalWrite(ledPin_, HIGH);
            state_ = true;
            return true;
        }
    } else if (!digitalRead(switchPin_)) {
        digitalWrite(ledPin_, LOW);
        state_ = false;
    }
    return false;
}

void Effect::printMessage() {
    char* p = static_cast<char*>(malloc(80));
    sprintf(p, "%s: COUNT=%d, PTR=%p", name_, count_++, p);
    println(p);
    free(p);
}
