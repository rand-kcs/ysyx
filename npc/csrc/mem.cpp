#include <cstdio>
#define MEM_HEADER
#include <cstdint>
#include <cmath>
#include <cstring>
#include "mem.h"
#include "utils.h"
#include "macro.h"
#include "cpu.h"

void difftest_skip_ref();

uint32_t img [] = {
	// 0x00100093, // addi r1, r0, 1
	//  0x00108133, // addi x2, x1, x1
	// 0x0000a1b7, // lui x3, 10
	//  0x0000b113, // sltiu x2, x1, 0
	// 0x00001217, // auipc x4, 1<<12
  0xa00002b7,  // lui t0, 0xa0000        # 加载高20位到t0
  0x3f828293,  // addi t0, t0, 0x3f8     # 加上低12位偏移
  0x04800313,  //li t1, 0x48            # 加载字符'H'
  0x00628023,  //sb t1, 0(t0)           # 存储到UART
	0x004002ef, // jal x5, 4
  0x00c28293, //addi x5, x5, 12
  0x30529073, //csrrw x0, mtvec, x5
  0x00000073, //ecall
  
	0x004002ef, // jal x5, 4
  0x01028293,// addi x5, x5, 16
  0x34129073, // csrrw x0, mepc, x5
  0x30200073, // mret
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
  0x04300093, //addi x1, x0, 67
	0x34209073, // csrw mcaus, r1
	0x34202173, // csrr r2,mcause
	0x00100073, // ebreak;
	0x000000,
};

uint8_t pmem[CONFIG_MSIZE] = {};

uint8_t mrom[CONFIG_MROM_SIZE] = {};

uint32_t flash[CONFIG_FLASH_SIZE] = {
  0x100007b7,
  0x04100713,
  0x00e78023,
  0x00000793,
  0x00078513,
  0x00100073,
  0x00008067,
};

void load_default_img(){
  memcpy(guest_to_host(RESET_VECTOR), img, sizeof(img));
}

// pmem as pointer type, add 1 equals to add 4 in real place.
//paddr_t host_to_guest(uint8_t *haddr) { return haddr     - pmem + CONFIG_MBASE; }

uint8_t* guest_to_host(paddr_t paddr) { return (uint8_t*)pmem +  (paddr - CONFIG_MBASE)  ; }

uint8_t* guest_to_host_mrom(paddr_t paddr) 
{ if(paddr >= 0x20000000 && paddr <= 0x20000fff)
    return (uint8_t*)mrom +  (paddr - CONFIG_MROM_BASE) ; 
  else 
    Log("Inst addr not in mrom 0x%08x, Return zero\n", paddr);
    return 0;
}

uint8_t* guest_to_host_flash(paddr_t paddr) { return (uint8_t*)flash +  (paddr&0xffffff)  ; }


extern "C" void mrom_read(int32_t addr, int32_t *data) {
  // Log("READING MROM AT 0x%08x \n", addr);
  // print_reg_status();
  char holder[256];
  sprintf(holder,"[npc]: Reading addr 0x%08x\n", addr);
  RF_Write(&mring_buf, holder);
  *data = *(uint32_t*)guest_to_host_mrom(addr);
}


extern "C" void flash_read(int32_t addr, int32_t *data) {
   //Log("READING FLASH AT 0x%08x \n", addr);
   //print_reg_status();
  char holder[256];
  sprintf(holder,"[npc]: Reading addr(flash) 0x%08x\n", addr);
  RF_Write(&mring_buf, holder);

    *data = *(uint32_t*)guest_to_host_flash(addr);
}


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
  //log_write("[npc]: Reading addr 0x%08x\n", addr);
  char holder[256];
  sprintf(holder,"[npc]: Reading addr 0x%08x\n", addr);
  RF_Write(&mring_buf, holder);

  if(addr == RTC_ADDR){
    difftest_skip_ref();
    uint64_t us = get_time();
    rtc_port_base[0] = (uint32_t)us;
    rtc_port_base[1] = us >> 32;
    return rtc_port_base[0];
  }

  if(addr == RTC_ADDR + 4){
    difftest_skip_ref();
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
  char holder[256];
  sprintf(holder,"[npc]: Writing addr 0x%08x, with data: 0x%08x, with wmask: 0x%04x\n", waddr, wdata, wmask);
  RF_Write(&mring_buf, holder);

  if(waddr == SERIAL_PORT){
    difftest_skip_ref();
    Assert(wmask == 0x1, "Writing more than char at once");
    putc(wdata, stderr);
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
