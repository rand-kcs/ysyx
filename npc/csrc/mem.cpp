#define MEM_HEADER
#include <cstdint>
#include <cmath>
#include "mem.h"
#include "utils.h"


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

static inline bool in_pmem(paddr_t addr) {
  return addr - CONFIG_MBASE < CONFIG_MSIZE;
}
extern "C" int pmem_read(int addr) {
  Log("[npc]: Reading addr 0x%08x\n", addr);
  if(in_pmem(addr)){
  word_t ret = *guest_to_host(addr);
  return ret;
  }else 
    Log("PMEM OUT OF BOUND\n");
  return 0;
}

extern "C" void pmem_write(int waddr, int wdata, char wmask) {
  // 总是往地址为`waddr & ~0x3u`的4字节按写掩码`wmask`写入`wdata`
  // `wmask`中每比特表示`wdata`中1个字节的掩码,
  // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
  //
  switch (wmask) {
    case 0x1:
    *(uint8_t*)guest_to_host(waddr & ~0x3u) = wdata;
      break;
    case 0x3:
    *(uint16_t*)guest_to_host(waddr & ~0x3u) = wdata;
      break;
    case 0xf:
    *(uint32_t*)guest_to_host(waddr & ~0x3u) = wdata;
      break;
    default:
      printf("wmask Error");
      break;
  }
}
