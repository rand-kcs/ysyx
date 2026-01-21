#include "cpu.h"
#include "mem.h"
#include "utils.h"
#include "macro.h"
#include "svdpi.h"

void print_reg_status() {
  #ifdef NPC_DEBUG
  for(int i = 0; i < 32; i++){
    printf("r%d : 0x%08x\n", i, tb->rf_dbg[i]);
  }
  #endif
}


const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};


word_t isa_reg_str2val(const char *s, bool *success) {
  #ifdef NPC_DEBUG
	for(int i = 0; i < ARRLEN(regs); i++){
		if(strcmp(regs[i], s) == 0)	
			return tb->rf_dbg[i];
	}
	
	if(strcmp(s, "pc") == 0) {
		return tb->pc;
	}
	
	*success = false;
  #endif
	return 0;
}



void single_cycle() {                      
   tb->clock = 0; tb->eval();
   contextp->timeInc(1);
   tb->clock= 1; tb->eval();
   contextp->timeInc(1);
 }

