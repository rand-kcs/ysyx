#include <am.h>
#include <riscv/riscv.h>
#include <klib-macros.h>
#include "include/soc.h"
#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern char _heap_start;
int main(const char *args);

extern char _mrom_start;
#define MROM_SIZE (1 * 16 * 16* 16)
#define MROM_END  ((uintptr_t)&_mrom_start + MROM_SIZE  -1 )

extern char _sram_start[];
#define SRAM_SIZE (0x2000)
#define SRAM_END (_sram_start + SRAM_SIZE - 1)

extern char _psram_start[];
#define PSRAM_SIZE (0x400000)
#define PSRAM_END (_psram_start + PSRAM_SIZE - 1)

Area heap = RANGE(&_heap_start, PSRAM_END);
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

void putch(char ch) {
  while ((inb(UART_LSR) & (1<<5)) == 0);
  outb(SERIAL_PORT, ch);
}

void halt(int code) {
	asm volatile("mv a0, %0; ebreak" : :"r"(code));
  while (1);
}

extern char _erodata[];
extern char _edata[];
extern char _data[];

void _trm_init() {
  // 10000011b
  // 1. enable divisor latch access
  outb(0x10000003,0x83);

  // 2. set divisor latch byte  LSB
  outb(0x10000000,0x10);

  // 3. disable divisor latch access
  outb(0x10000003,0x03);

  // 4. FCR fifo control 
  outb(0x10000002,0xff);

  // uintptr_t id;
  // asm volatile("csrr %0, 0xf11" : "=r"(id));
  // printf("Vendor ID: 0x%x\n", id);
  //
  // asm volatile("csrr %0, 0xf12" : "=r"(id));
  // printf("Arch ID: %x\n", id);

  int ret = main(mainargs);
  halt(ret);
}
