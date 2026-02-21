ENTRY(_start)
/*PHDRS { boot PT_LOAD; text PT_LOAD; data PT_LOAD; }*/

_flash_start = 0x30000000;
_sram_start =  0x0f000000;
_psram_start = 0x80000000;
_sdram_start = 0xa0000000;

MEMORY
{
    FLASH (rx) : ORIGIN = 0x30000000, LENGTH = 256M
    SRAM (rwx)  : ORIGIN = 0x0f000000, LENGTH = 8K
    PSRAM (rwx)  : ORIGIN = 0x80000000, LENGTH = 4M
    SDRAM (rwx)  : ORIGIN = 0xa0000000, LENGTH = 32M
}

SECTIONS {
  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = _flash_start+ _entry_offset;

  .fsbl : {
    *(entry)
    *(.fsbl)
    . = ALIGN(4);
  }  > FLASH AT > FLASH
  _efsbl = . ;

  .ssbl :
  {
    _ssbl_start = . ;
    *(.ssbl) 
    . = ALIGN(4);
    _essbl = . ;
  } > SRAM AT >FLASH
  /* 显式定义 SSBL 的 LMA 起始位置，供 FSBL 搬运用 */
  _ssbl_lma_start = LOADADDR(.ssbl);

  .text : 
  {
    _text_start = . ;
    *(.text*)
    *(.rodata*)
    *(.srodata*)
    . = ALIGN(8);
  }  > SDRAM AT > FLASH
  _text_lma_start = LOADADDR(.text);
  _etext = . ;

  /*_erodata = . ;*/
  /*.rodata : {*/
  /*}*/
  .data :
    { 
      _data = .;
      *(.data.*)
      *(.sdata.*)
    /* extra.ld */
    __fsymtab_start = .;
    KEEP(*(FSymTab))
    __fsymtab_end = .;
    . = ALIGN(8);
    __vsymtab_start = .;
    KEEP(*(VSymTab))
    __vsymtab_end = .;
    . = ALIGN(8);

    /* section information for initial. */
    . = ALIGN(8);
    __rt_init_start = .;
    KEEP(*(SORT(.rti_fn*)))
    __rt_init_end = .;
    . = ALIGN(8);

    __rt_utest_tc_tab_start = .;
    KEEP(*(UtestTcTab))
    __rt_utest_tc_tab_end = .;

    . = ALIGN(8);
    __am_apps_data_start = .;
    *(__am_apps.data*)
    *(__am_apps.sdata*)
    __am_apps_data_end = .;
    . = ALIGN(8);

      _edata = .;
    } > SDRAM AT > FLASH
  _data_lma_start = LOADADDR(.data);

  _bss = .;
  .bss (NOLOAD) : 
  {
	  _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)

    . = ALIGN(8);
    __am_apps_bss_start = .;
    *(__am_apps.bss*)
    *(__am_apps.sbss*)
    *(__am_apps.scommon*)
    __am_apps_bss_end = .;
    . = ALIGN(8);

  } > SDRAM 
  _ebss = .;


  _stack_top = _psram_start ;
  . = _stack_top + 0x200000;
  _stack_pointer = .;
  end = .;
  _end = .;
  _heap_start = ALIGN(0x0004);
  _heap_end = _psram_start + 0x3fffff;

}
