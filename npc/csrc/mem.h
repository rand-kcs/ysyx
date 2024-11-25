#define CONFIG_MBASE 0x80000000

typedef uint32_t word_t;
typedef uint32_t paddr_t;

uint32_t pmem[] = {
	0x00100093, // addi r1, r0, 1
	0x00108113, // addi r2, r1, 1
	0x00100073,
	0x000000,
};

uint32_t* guest_to_host(paddr_t paddr) { return pmem +     (paddr - CONFIG_MBASE) / 4; }
//paddr_t host_to_guest(uint8_t *haddr) { return haddr     - pmem + CONFIG_MBASE; }

word_t pmem_read(paddr_t addr) {
  word_t ret = *guest_to_host(addr);
  return ret;
}
 
