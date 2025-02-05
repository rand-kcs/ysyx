#define MEM_HEADER
#include <cstdint>
#include "mem.h"


uint32_t pmem[CONFIG_MSIZE] = {
	0x00100093, // addi r1, r0, 1
	0x00108113, // addi r2, r1, 1
	0x0000a1b7, // lui x3, 10
	0x00001217, // auipc x4, 1<<12
	0x004002ef, // jal x5, 4
	0x00428367, // jalr x6, 4(x5)
	0x00100073, // ebreak;
	0x000000,
};

// pmem as pointer type, add 1 equals to add 4 in real place.
uint32_t* guest_to_host(paddr_t paddr) { return pmem +     (paddr - CONFIG_MBASE) / 4; }
//paddr_t host_to_guest(uint8_t *haddr) { return haddr     - pmem + CONFIG_MBASE; }

word_t pmem_read(paddr_t addr) {
  word_t ret = *guest_to_host(addr);
  return ret;
}

