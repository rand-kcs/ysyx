#include "cpu.h"
#include "mem.h"
#include "utils.h"
#include "macro.h"
#include "svdpi.h"
#include "VDUT__Dpi.h"
#include "VDUT___024root.h"
#include "VDUT__Syms.h"
#include <cstdint>
#include <nvboard.h>

void nvboard_update();
const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};


uint32_t cpu_gpr(int i) { return tb->rootp->vlSymsp->TOP__ysyxSoCFull__asic__cpu__cpu.rf_dbg[i]; }

uint32_t cpu_pc() {return tb->rootp->vlSymsp->TOP__ysyxSoCFull__asic__cpu__cpu.pc ; }

uint32_t cpu_done() {return tb->rootp->vlSymsp->TOP__ysyxSoCFull__asic__cpu__cpu.done; }

void print_reg_status() {
  for(int i = 0; i < 32; i++){
    printf("reg[%d] (%s) : 0x%08x\n", i, regs[i], cpu_gpr(i));
  }
}


word_t isa_reg_str2val(const char *s, bool *success) {
	for(int i = 0; i < ARRLEN(regs); i++){
		if(strcmp(regs[i], s) == 0)	
			return cpu_gpr(i);
	}
	
	if(strcmp(s, "pc") == 0) {
		return cpu_pc();
	}
	
	*success = false;
	return 0;
}



void single_cycle() {                      
   nvboard_update();
   tb->clock = 0; tb->eval();
   contextp->timeInc(1);
   tb->clock= 1; tb->eval();
   contextp->timeInc(1);
 }

