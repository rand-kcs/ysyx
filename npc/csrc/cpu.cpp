#include "cpu.h"
#include "mem.h"
#include "utils.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"

void print_reg_status() {
  for(int i = 0; i < 32; i++){
    printf("r%d : 0x%08x\n", i, tb->rf_dbg[i]);
  }
}


void single_cycle() {                      
   contextp->timeInc(1);
   tb->clk = 0; tb->eval();
   contextp->timeInc(1);
   tb->clk = 1; tb->eval();
 }

