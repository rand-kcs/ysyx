ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }

SECTIONS {
  /* _pmem_start and _entry_offset are defined in LDFLAGS */
  . = _mrom_start + _entry_offset;
  .text : {
    *(entry)
    *(.text*)
  } : text
  etext = . ;
  _etext = . ;
  .rodata : {
    *(.rodata*)
  }
  . = ALIGN(4);
  _erodata = . ;

  .data 0x0f000000 :
    AT (_erodata)
    { 
      _data = .;
      *(.data.*)
    } : data
  edata = .;

  .bss : 
    AT ( LOADADDR(.data) + SIZEOF(.data))
  {
	  _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  }
  _edata = .;

  _stack_top = ALIGN(0x1000);
  . = _stack_top + 0x8000;
  _stack_pointer = .;
  end = .;
  _end = .;
  _heap_start = ALIGN(0x1000);
}
