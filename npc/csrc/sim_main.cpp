#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <verilated.h>
#include "Vtestbench.h"

int main(int argc, char** argv){
	//Verilated::mkdir("logs");

	// Construct a VerilatedContext to hold simulation time, etc.
	VerilatedContext* contextp = new VerilatedContext;
	
	// Verilator must compute traced signals
	contextp->traceEverOn(true);

	// Pass arguments so Verilated code can see them, e.g. $value$plusargs
	// This need to be called berfore create any mode;
	contextp->commandArgs(argc, argv);

	//Construct the Verilated Model, From VtestBench.h 
	Vtestbench* tb = new Vtestbench{contextp};

	// Set Vtop's input;

	//Simulate until $finish
	while(!contextp -> gotFinish()) {
		contextp->timeInc(1);
		int a = rand() & 1;
		int b = rand() & 1;
		tb->a = a;
		tb->b = b;
		tb->eval()	;

		printf("a = %d, b = %d, f = %d\n", a, b, tb->f);
		assert(tb->f == (a^b));
	} 
	tb->final();
	delete tb;


	printf("Simulation Done.\n");
	

}
