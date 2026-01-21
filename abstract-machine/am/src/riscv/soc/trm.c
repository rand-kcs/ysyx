#include <am.h>
#include <riscv/riscv.h>
#include <klib-macros.h>
#include "include/soc.h"
#include <string.h>

extern char _heap_start;
int main(const char *args);

extern char _mrom_start;
#define MROM_SIZE (1 * 16 * 16* 16)
#define MROM_END  ((uintptr_t)&_mrom_start + MROM_SIZE)

extern char _sram_start[];
#define SRAM_SIZE (0x2000)
#define SRAM_END (_sram_start + SRAM_SIZE)

Area heap = RANGE(&_heap_start, SRAM_END);
#ifndef MAINARGS
#define MAINARGS ""
#endif
static const char mainargs[] = MAINARGS;

void putch(char ch) {
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
  // copy data from rom to ram
  memcpy(_sram_start, _erodata, (_edata - _data));

  int ret = main(mainargs);
  halt(ret);
}
