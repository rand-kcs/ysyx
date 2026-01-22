#include <verilated.h>
#include "VDUT.h"
#include "macro.h"

extern VDUT* tb;
extern VerilatedContext* contextp;

void cpu_exec(uint64_t);
void single_cycle();
void print_reg_status();
word_t isa_reg_str2val(const char *s, bool *success);
	 
struct CPU_state{
	uint32_t gpr[32];
	uint32_t pc;
};

uint32_t cpu_gpr(int i);

uint32_t cpu_pc();

uint32_t cpu_done();


extern CPU_state cpu ;
