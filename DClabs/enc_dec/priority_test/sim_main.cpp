#include <verilated.h>
#include "verilated_fst_c.h"
#include <Vencode42.h>

static VerilatedContext* contextp = new VerilatedContext;
static Vencode42* top = new Vencode42;
static VerilatedFstC* tfp = new VerilatedFstC;


void step_and_dump_wave() {
		contextp->timeInc(1);
		top->eval();
		tfp->dump(contextp->time());
}

int main(int argc, char**argv) {
	contextp->traceEverOn(true);
	contextp->commandArgs(argc, argv);

	top->trace(tfp, 99);
	tfp->open("waves/vlt_dump.fst");

	top->en=0b0; top->x =0b0000; step_and_dump_wave();printf("top-out: %x\n",top->y);
               top->x =0b0001; step_and_dump_wave();printf("top-out: %x\n",top->y);
               top->x =0b0010; step_and_dump_wave();printf("top-out: %x\n",top->y);
               top->x =0b0100; step_and_dump_wave();printf("top-out: %x\n",top->y);
               top->x =0b1000; step_and_dump_wave();printf("top-out: %x\n",top->y);
  top->en=0b1; top->x =0b1100; step_and_dump_wave();printf("top-out: %x\n",top->y);
               top->x =0b0111; step_and_dump_wave();printf("top-out: %x\n",top->y);
               top->x =0b0011; step_and_dump_wave();printf("top-out: %x\n",top->y);
               top->x =0b0101; step_and_dump_wave();printf("top-out: %x\n",top->y);
               top->x =0b1111; step_and_dump_wave();printf("top-out: %x\n",top->y);
               top->x =0b1000; step_and_dump_wave();printf("top-out: %x\n",top->y);
               top->x =0b0110; step_and_dump_wave();printf("top-out: %x\n",top->y);
               top->x =0b0110; step_and_dump_wave();printf("top-out: %x\n",top->y);

	top->final();
	tfp->close();
}
