/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include "common.h"
#include <assert.h>
#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>
#include <isa.h>
#include <stdlib.h>

#define CONFIG_AM_SRAM
#define CONFIG_AM_SRAM_BASE 0x0f000000
#define CONFIG_AM_SRAM_SIZE 0x2000

#define CONFIG_AM_PSRAM_BASE 0x80000000
#define CONFIG_AM_PSRAM_SIZE 0x20000000

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif


#ifdef CONFIG_AM_SRAM
uint8_t *sram;
uint8_t *psram;

bool in_sram(paddr_t addr){ return addr >= CONFIG_AM_SRAM_BASE && addr < CONFIG_AM_SRAM_BASE + CONFIG_AM_SRAM_SIZE; }
bool in_psram(paddr_t addr){ return addr >= CONFIG_AM_PSRAM_BASE && addr < CONFIG_AM_PSRAM_BASE + CONFIG_AM_PSRAM_SIZE; }

static word_t sram_read(paddr_t addr, int len) {
#ifdef CONFIG_MTRACE
	log_write("mem reading addr: " FMT_WORD " with len: %d\n", addr, len);
#endif
  word_t ret = host_read(sram + addr - CONFIG_AM_SRAM_BASE, len);
  return ret;
}

static void sram_write(paddr_t addr, int len, word_t data) {
#ifdef CONFIG_MTRACE
	log_write("mem writing addr: " FMT_WORD " with len: %d, wdata: " FMT_WORD " \n", addr, len, data);
#endif
  host_write(sram + addr - CONFIG_AM_SRAM_BASE, len, data);
}

static word_t psram_read(paddr_t addr, int len) {
#ifdef CONFIG_MTRACE
	log_write("mem reading addr: " FMT_WORD " with len: %d\n", addr, len);
#endif
  word_t ret = host_read(psram + addr - CONFIG_AM_PSRAM_BASE, len);
  return ret;
}
static void psram_write(paddr_t addr, int len, word_t data) {
#ifdef CONFIG_MTRACE
	log_write("psram writing addr: " FMT_WORD " with len: %d, wdata: " FMT_WORD " \n", addr, len, data);
#endif
  host_write(psram + addr - CONFIG_AM_PSRAM_BASE, len, data);
}

#endif

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static word_t pmem_read(paddr_t addr, int len) {
#ifdef CONFIG_MTRACE
	log_write("mem reading addr: " FMT_WORD " with len: %d\n", addr, len);
#endif
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
#ifdef CONFIG_MTRACE
	log_write("mem writing addr: " FMT_WORD " with len: %d, wdata: " FMT_WORD " \n", addr, len, data);
#endif
  host_write(guest_to_host(addr), len, data);
}

static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif

#ifdef CONFIG_AM_SRAM
  sram = malloc(CONFIG_AM_SRAM_SIZE);
  assert(sram);

  psram = malloc(CONFIG_AM_PSRAM_SIZE);
  assert(psram);
#endif

  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE));
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}

word_t paddr_read(paddr_t addr, int len) {
  //printf("nemu Read At %x, lengh: %d\n", addr, len);
  if (likely(in_pmem(addr))) return pmem_read(addr, len);
#ifdef CONFIG_AM_SRAM
  if (likely(in_sram(addr))) return sram_read(addr, len);
  if (likely(in_psram(addr))) return psram_read(addr, len);
#endif
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  // flash 0x3000 0000 ~ 0x3fff ffff
  if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }

#ifdef CONFIG_AM_SRAM
  // SRAM 0x0f00 0000 0x0f00 1fff
  if (likely(in_sram(addr))) { sram_write(addr, len, data); return; }
  if (likely(in_psram(addr))) { psram_write(addr, len, data); return; }
  // SERIAL DEVIECE OUTPUT
  // skip difftest
  if(addr >= 0x10000000 && addr <= 0x10000007) return;
#endif

  IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
  out_of_bound(addr);
}
