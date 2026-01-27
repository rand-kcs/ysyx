AM_SRCS := riscv/soc/start.S \
           riscv/soc/trm.c \
           riscv/soc/ioe.c \
           riscv/soc/timer.c \
           riscv/soc/input.c \
           riscv/soc/cte.c \
           riscv/soc/trap.S \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
LDFLAGS   += -T $(AM_HOME)/scripts/soc_linker.ld \
						 --defsym=_mrom_start=0x20000000 --defsym=_entry_offset=0x0 \
						 --defsym=_sram_start=0x0f000000 
LDFLAGS   += --gc-sections -e _start
CFLAGS += -DMAINARGS=\"$(mainargs)\"
CFLAGS += -I$(AM_HOME)/am/src/riscv/npc/include


ifeq ($(BATCH),1)
   # LDFLAGS += --gc-sections
   # CFLAGS  += -ffunction-sections -fdata-sections
	  SOCFLAGS+= -b
endif





.PHONY: $(AM_HOME)/am/src/riscv/npc/trm.c

# 不将.bss 段的内容加载 进.bin 中
#--set-section-flags .bss=alloc,contents
image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S  -O binary $(IMAGE).elf $(IMAGE).bin

run: image
	$(MAKE) -C $(NPC_HOME) run ARGS="$(SOCFLAGS)" MROM=$(IMAGE).bin  LOGFILE=$(shell dirname $(IMAGE).elf)/soc-log.txt 
