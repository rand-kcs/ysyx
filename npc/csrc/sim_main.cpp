#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <verilated.h>
#include "Vtop.h"
#include "mem.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"

Vtop* tb;
VerilatedContext* contextp;

static void single_cycle() {
	contextp->timeInc(1);
  tb->clk = 0; tb->eval();
	contextp->timeInc(1);
  tb->clk = 1; tb->eval();
}

static void reset(int n) {
  tb->rst = 1;
  while (n -- > 0) single_cycle();
  tb->rst = 0;
}
 
void print_reg_status() {
	for(int i = 0; i < 32; i++){
		printf("r%d : 0x%08x\n", i, tb->rf_dbg[i]);
	}
}



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
	tb = new Vtop{contextp};

	const svScope scope = svGetScopeFromName("TOP.top");
	assert(scope);  // Check for nullptr if scope not found
	svSetScope(scope);


	// Set Vtop's input;
	reset(5);
	//Simulate until $finish
	while(!contextp -> gotFinish()) {
		tb->inst = pmem_read(tb->pc);
		printf("INST: 0x%08x by pc: 0x%x \n", tb->inst, tb->pc);
		single_cycle();
		print_reg_status();
		if(ebreakYes())
			break;
	} 
	tb->final();
	delete tb;


	printf("Simulation Done.\n");
	

}
