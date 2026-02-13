#include <string.h>
#include <stdint.h>

void _trm_init();
extern char _eboot[];
extern char _efsbl[];
extern char _essbl[];
extern char _text_start[];
extern char _sram_start[];
extern char _ssbl_start[];
extern char _psram_start[];
extern char _data[];
extern char _edata[];
extern char _etext[];
extern char _ebss[];
extern char _bss[];

extern char _text_lma_start[];
extern char _data_lma_start[];
extern char _ssbl_lma_start[];

void __attribute__((section(".ssbl"), noinline)) _ss_bootloader(){
  // copy data from flash to sram
    // 1. 定义字符指针
    volatile char *src = (volatile char *)_text_lma_start;
    volatile char *dst = (volatile char *)_text_start;

    // 2. 计算字节长度
    size_t length_in_bytes = (size_t)((char *)_etext - (char *)_text_start);

    // 3. 逐字节搬运
    while (length_in_bytes > 0) {
        *dst++ = *src++;
        length_in_bytes--;
    }

    src = (volatile char *)_data_lma_start;
    dst = (volatile char *)_data;
    while (dst < (volatile char *)_edata) {
        *dst++ = *src++;
    }



  // set .bss zero
  volatile uint32_t *dst2 = (volatile uint32_t *)_bss;
  volatile uint32_t *end2 = (volatile uint32_t *)_ebss;

    // 2. 逐个 4 字节清零
    while (dst2 < end2) {
        *dst2++ = 0;
    }

  _trm_init();
}

void __attribute__((section(".fsbl"), noinline)) _fs_bootloader(){
  // copy data from flash to sram
    // 1. 定义字符指针
    volatile char *src = (volatile char *)_ssbl_lma_start;
    volatile char *dst = (volatile char *)_ssbl_start;

    // 2. 计算字节长度
    size_t length_in_bytes = (size_t)((char *)_essbl - (char *)_ssbl_start);

    // 3. 逐字节搬运
    while (length_in_bytes > 0) {
        *dst++ = *src++;
        length_in_bytes--;
    }
  _ss_bootloader();
}
