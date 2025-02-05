#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <verilated.h>
#include <cstdint>
#include <cstddef>
#include "Vtop.h"
#include "mem.h"
#include "utils.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"
#include "cpu.h"

Vtop* tb;
VerilatedContext* contextp;
void init_monitor(int, char**);
void sdb_main_loop();
int is_exit_status_bad() ;

static void reset(int n) {
  tb->rst = 1;
  while (n -- > 0) single_cycle();
  tb->rst = 0;
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

	init_monitor(argc, argv);
	//Simulate until $finish

	/*  Old npc exec logic
	while(!contextp -> gotFinish()) {

	} 
  */

	// SDB import
	sdb_main_loop();

	tb->final();
	delete tb;


	printf("Simulation Done.\n");
	
	return is_exit_status_bad();
}
