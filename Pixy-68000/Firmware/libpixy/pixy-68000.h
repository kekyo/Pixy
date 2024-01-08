#ifndef __PIXY_68000_H
#define __PIXY_68000_H

#pragma once

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

void digitalWrite(uint8_t pin, uint8_t val);
int digitalRead(uint8_t pin);

bool havebyte();
uint8_t inbyte();
bool canSend();
void outbyte(uint8_t ch);

void setEcho(bool echoBack);

void print(const char *pStr);
void println(const char *pStr);

uint32_t millis();

#endif
