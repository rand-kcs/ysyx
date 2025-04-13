#define MEM_HEADER
#include <cstdint>
#include <cmath>
#include <cstring>
#include "mem.h"
#include "utils.h"


uint32_t img [] = {
	0x00100093, // addi r1, r0, 1
	0x34209073, // csrw mcaus, r1
	0x34202173, // csrr r2,mcause

  0x0000b113, // sltiu x2, x1, 0
  0x00108133, // add x2, x1, x1
	0x00108113, // addi r2, r1, 1
	0x0000a1b7, // lui x3, 10
	0x00001217, // auipc x4, 1<<12
	0x004002ef, // jal x5, 4
	0x00428367, // jalr x6, 4(x5)
	0x00100093, // addi r1, r0, 1
  0x0002a383, //  lw x7, 0(x5)
  0x00029383, // lh x7, 0(x5)
  0x00028383, // lb x7, 0(x5)
  0x0002c383, // lbu x7, 0(x5)
  0x0002d383, // lhu x7, 0(x5)
  0x00628023,   // sb x6 0(x5)
  0x0002a403,    // lw x8,0(x5)
  0x00629023,   // sh x6 0(x5)
  0x0002a403,   // lw x8,0(x5)
  0x0062a023,   // sw x6 0(x5)
  0x0002a403,    // lw x8,0(x5)
  0x0062a223,    // sw x6,4(x5)
  0x0042a403,    // lw x8,4(x5)
  0x00028283,  // lb x5,0(x5)
  0x00100073, // ebreak;
	0x000000,
};

uint8_t pmem[CONFIG_MSIZE] = {};

void load_default_img(){
  memcpy(guest_to_host(RESET_VECTOR), img, sizeof(img));
}

// pmem as pointer type, add 1 equals to add 4 in real place.
uint8_t* guest_to_host(paddr_t paddr) { return (uint8_t*)pmem +  (paddr - CONFIG_MBASE)  ; }
//paddr_t host_to_guest(uint8_t *haddr) { return haddr     - pmem + CONFIG_MBASE; }

static inline bool in_pmem(paddr_t addr) {
  return addr - CONFIG_MBASE < CONFIG_MSIZE;
}

int pmem_read_trace(int addr) {
  if(in_pmem(addr)){
  word_t ret = *(uint32_t*)guest_to_host(addr);
  return ret;
  }else 
    Log("PMEM OUT OF BOUND\n");
  return 0;
}

static uint32_t *rtc_port_base[2];
extern "C" int pmem_read(int addr) {
  log_write("[npc]: Reading addr 0x%08x\n", addr);

  if(addr == RTC_ADDR){
    uint64_t us = get_time();
    rtc_port_base[0] = (uint32_t)us;
    rtc_port_base[1] = us >> 32;
    return rtc_port_base[0];
  }

  if(addr == RTC_ADDR + 4){
    uint64_t us = get_time();
    rtc_port_base[0] = (uint32_t)us;
    rtc_port_base[1] = us >> 32;
    return rtc_port_base[1];
  }

  if(in_pmem(addr)){
    word_t ret = *(uint32_t*)guest_to_host(addr);
    return ret;
  }

  // npc Write along with read;
  log_write("PMEM OUT OF BOUND\n");
  
  return 0;
}

extern "C" void pmem_write(int waddr, int wdata, char wmask) {
  // 总是往地址为`waddr & ~0x3u`的4字节按写掩码`wmask`写入`wdata`
  // `wmask`中每比特表示`wdata`中1个字节的掩码,
  // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
  //
  if(waddr == SERIAL_PORT){
    Assert(wmask == 0x1, "Writing more than char at once");
    putchar(wdata);
    return;
  }
  switch (wmask) {
    case 0x1:
    *(uint8_t*)guest_to_host(waddr) = wdata;
      break;
    case 0x3:
    *(uint16_t*)guest_to_host(waddr) = wdata;
      break;
    case 0xf:
    *(uint32_t*)guest_to_host(waddr) = wdata;
      break;
    default:
      printf("wmask Error");
      break;
  }
}
