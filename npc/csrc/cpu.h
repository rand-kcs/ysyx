#include <verilated.h>
#include "Vtop.h"

extern Vtop* tb;
extern VerilatedContext* contextp;

void cpu_exec(uint64_t);
void single_cycle();
void print_reg_status();
	 
struct CPU_state{
	uint32_t gpr[32];
	uint32_t pc;
};


extern CPU_state cpu ;
