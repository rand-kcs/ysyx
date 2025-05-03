#include <set>
#include <stdio.h>
#include <dlfcn.h>
#include "cpu.h"
#include "mem.h"
#include "utils.h"
#include "difftest.h"
#include "macro.h"

void (*ref_difftest_memcpy)(paddr_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;


static bool is_skip_ref = false;

void difftest_skip_ref() {
  is_skip_ref = true;
}

void init_difftest(char *ref_so_file, long img_size, int port) {
  assert(ref_so_file != NULL);

  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  ref_difftest_memcpy = dlsym(handle, "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  void (*ref_difftest_init)(int) = dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  Log("Differential testing: %s", ANSI_FMT("ON", ANSI_FG_GREEN));
  Log("The result of every instruction will be compared with %s. "
      "This will help you a lot for debugging, but also significantly reduce the performance. "
      "If it is not necessary, you can turn it off in menuconfig.", ref_so_file);

  ref_difftest_init(port);
  ref_difftest_memcpy(RESET_VECTOR, guest_to_host(RESET_VECTOR), img_size, DIFFTEST_TO_REF);
  cpu.pc = RESET_VECTOR;
  ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
}

bool isa_difftest_checkregs(CPU_state *ref) {
  for(int i = 0; i < RISCV_GPR_NUM; i++){
    if(ref->gpr[i] != tb->rf_dbg[i]) {
       Log("Reg dont Match! id: %d\ntb: 0x%08x\nref: 0x%08x", i, tb->rf_dbg[i], ref->gpr[i]) ;
      return false;
    }
  }
  if(ref->pc != tb->pc){
    Log("PC dont Match :\ntb: 0x%08x\nref: 0x%08x \n", tb->pc, ref->pc) ;
    return false;
  }

  Log("Diff Check Pass\n");
  return true;
}

static void checkregs(CPU_state *ref, vaddr_t pc) {
  if (!isa_difftest_checkregs(ref)) {
    npc_state.state = NPC_ABORT;
    npc_state.halt_pc = pc;
    print_reg_status();
  }
}

void set_cpu(){
  for(int i = 0; i < RISCV_GPR_NUM; i++){
    cpu.gpr[i] = tb->rf_dbg[i];
  }
  cpu.pc = tb->pc;
}

void difftest_step(vaddr_t pc, vaddr_t npc) {
  CPU_state ref_r;

  if(is_skip_ref)  {
    log_write("nemu skip at pc: " FMT_PADDR, pc);
    set_cpu();
    ref_difftest_regcpy(&cpu, DIFFTEST_TO_REF);
    is_skip_ref = false;
    return;
  }

  ref_difftest_exec(1);
  ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);

  checkregs(&ref_r, pc);
}
