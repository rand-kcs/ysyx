#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <verilated.h>
#include <cstdint>
#include <cstddef>
#include "VDUT.h"
#include "mem.h"
#include "utils.h"
#include "svdpi.h"
#include "VDUT__Dpi.h"
#include "cpu.h"
#include "VDUT___024root.h"
#include "VDUT__Syms.h"

VDUT* tb;
VerilatedContext* contextp;
void init_monitor(int, char**);
void sdb_main_loop();
int is_exit_status_bad() ;

static void reset(int n) {
  tb->reset = 1;
  while (n -- > 0) single_cycle();
  tb->reset = 0;

  while(tb->rootp->vlSymsp->TOP__ysyxSoCFull__asic__cpu__cpu.reset) single_cycle();
}

 
extern "C" void flash_read(int32_t addr, int32_t *data) { assert(0); }
// extern "C" void mrom_read(int32_t addr, int32_t *data) { 
//   printf("Calling MROM READ AT 0x%08x\n", addr);
//   *data = 0x00100073;
// }

int main(int argc, char** argv){
	//Verilated::mkdir("logs");

	// Construct a VerilatedContext to hold simulation time, etc.
	contextp = new VerilatedContext;
	
	// Verilator must compute traced signals
	contextp->traceEverOn(true);
	// Pass arguments so Verilated code can see them, e.g. $value$plusargs
	// This need to be called berfore create any mode;
	contextp->commandArgs(argc, argv);

	//Construct the Verilated Model, From Vtop.h 
	tb = new VDUT{contextp};

	const svScope scope = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu");
  // 在 Verilated 初始化之后，Scope 获取之前
  Verilated::scopesDump(); // 这会将所有 scope 打印到标准输出
	assert(scope);  // Check for nullptr if scope not found
	svSetScope(scope);



	init_monitor(argc, argv);
	//Simulate until $finish

	/*  Old npc exec logic
	while(!contextp -> gotFinish()) {

	} 
  */

	// Set Vtop's input;
	reset(10);

	// SDB import
	sdb_main_loop();

	tb->final();
	delete tb;

  MRF_Log();

  IRF_Log();
	printf("Simulation Done.\n");
	
	return is_exit_status_bad();
}
