#include <cstdint>
#define CONFIG_MBASE 0x80000000
#define CONFIG_MSIZE 0x8000000
#define RESET_VECTOR CONFIG_MBASE

typedef uint32_t word_t;
typedef uint32_t paddr_t;
typedef uint32_t vaddr_t;

extern uint8_t pmem[CONFIG_MSIZE];

void load_default_img();

// pmem as pointer type, add 1 equals to add 4 in real place.
uint8_t* guest_to_host(paddr_t paddr) ;
//paddr_t host_to_guest(uint8_t *haddr) { return haddr     - pmem + CONFIG_MBASE; }

extern "C" int pmem_read(int addr);
 
extern "C" void pmem_write(int waddr, int wdata, char wmask);


int pmem_read_trace(int addr) ;
