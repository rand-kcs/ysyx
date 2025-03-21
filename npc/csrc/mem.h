#include <cstdint>
#define CONFIG_MBASE 0x80000000
#define CONFIG_MSIZE 0x8000000
#define RESET_VECTOR CONFIG_MBASE

#define MMIO_BASE 0xa0000000
#define DEVICE_BASE MMIO_BASE

#define SERIAL_PORT     (DEVICE_BASE + 0x00003f8)
#define KBD_ADDR        (DEVICE_BASE + 0x0000060)
#define RTC_ADDR        (DEVICE_BASE + 0x0000048)
#define VGACTL_ADDR     (DEVICE_BASE + 0x0000100)
#define AUDIO_ADDR      (DEVICE_BASE + 0x0000200)
#define DISK_ADDR       (DEVICE_BASE + 0x0000300)
#define FB_ADDR         (MMIO_BASE   + 0x1000000)
#define AUDIO_SBUF_ADDR (MMIO_BASE   + 0x1200000)

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
