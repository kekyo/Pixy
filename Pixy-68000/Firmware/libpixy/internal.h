#ifndef __INTERNAL_H
#define __INTERNAL_H

#pragma once

#include "pixy-68000.h"

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/times.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#undef errno
extern int errno;

#define UART_SEND_BUSY 0x01
#define UART_RECEIVED 0x02
#define UART_ENABLE_SEND_INT 0x04
#define UART_ENABLE_RECEIVE_INT 0x08

#define TIMER_ENABLE_INT 0x01

#define __cli() { asm volatile ("oriw #0x0700,%%sr" : : : "memory"); } ((void)0)
#define __sti() { asm volatile ("andiw #0xf8ff,%%sr" : : : "memory"); } ((void)0)

static volatile uint8_t* const pSignal = (uint8_t*)0x00100001;
static volatile uint8_t* const pUartControl = (uint8_t*)0x00100003;
static volatile uint8_t* const pUartSendData = (uint8_t*)0x00100005;
static const volatile uint8_t* const pUartReceiveData = (uint8_t*)0x00100007;
static volatile uint8_t* const pTimerControl = (uint8_t*)0x00100009;
static const volatile uint16_t* const pTimerCount = (uint16_t*)0x0010000a;

#endif
