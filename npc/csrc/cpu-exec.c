#include "utils.h"
#include "mem.h"
#include "cpu.h"
#include "macro.h"
#include "svdpi.h"
#include "difftest.h"
#include "Vtop__Dpi.h"
#define MAX_INST_TO_PRINT 10

CPU_state cpu = {};
uint64_t g_nr_guest_inst = 0;
static uint64_t g_timer = 0; // unit: us
static bool g_print_step = false;

bool WP_trigger();
void IRF_Write(char* s);

uint32_t get_pc(){
	return cpu.pc;
}



static void trace_and_difftest() {
  /*---- Instruction Trace ---- */
  #ifdef ITRACE
	log_write("0x%08x : ", tb->pc);
	log_write("0x%08x ", tb->inst);

  char p[1024];
  memset(p, '\0', 1024);

  void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
  disassemble(p, sizeof(p),
      tb->pc, (uint8_t *)&tb->inst, 4);

  log_write(" %s\n",p);

  #endif
  /*---- Difftest ------*/
  
}


static void exec_once() {
  tb->inst = pmem_read(tb->pc);

  trace_and_difftest();

	single_cycle();

  #ifdef DIFFTEST
  /* difftest */
  difftest_step(tb->pc, tb->pc);
  #endif

	if(ebreakYes()){
		npc_state.state = NPC_END;
		npc_state.halt_pc = tb->pc;
  }
}

static void execute(uint64_t n) {
  for (;n > 0; n --) {
    exec_once();
    g_nr_guest_inst ++;
    if (npc_state.state != NPC_RUNNING) break;
  }
}

static void statistic() {
  IFNDEF(CONFIG_TARGET_AM, setlocale(LC_NUMERIC, ""));
#define NUMBERIC_FMT MUXDEF(CONFIG_TARGET_AM, "%", "%'") PRIu64
  Log("host time spent = " NUMBERIC_FMT " us", g_timer);
  Log("total guest instructions = " NUMBERIC_FMT, g_nr_guest_inst);
  if (g_timer > 0) Log("simulation frequency = " NUMBERIC_FMT " inst/s", g_nr_guest_inst * 1000000 / g_timer);
  else Log("Finish running in less than 1 us and can not calculate the simulation frequency");
}

void assert_fail_msg() {
	print_reg_status();
  statistic();
}

/* Simulate how the CPU works. */
void cpu_exec(uint64_t n) {
  g_print_step = (n < MAX_INST_TO_PRINT);
  switch (npc_state.state) {
    case NPC_END: case NPC_ABORT:
      printf("Program execution has ended. To restart the program, exit NPC and run again.\n");
      return;
    default: npc_state.state = NPC_RUNNING;
  }

  //uint64_t timer_start = get_time();

  execute(n);
	if(n < MAX_INST_TO_PRINT)
		printf("0x%08x : 0x%08x \n", tb->pc, tb->inst);

  //uint64_t timer_end = get_time();
  g_timer = 1;

  switch (npc_state.state) {
    case NPC_RUNNING: npc_state.state = NPC_STOP; break;

    case NPC_END: case NPC_ABORT:
      Log("npc: %s at snpc = " FMT_WORD,
          (npc_state.state == NPC_ABORT ? ANSI_FMT("ABORT", ANSI_FG_RED) :
           (npc_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
            ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
          npc_state.halt_pc);
      // fall through
    case NPC_QUIT: statistic();
  }
}
