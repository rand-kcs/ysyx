#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>
#include <stdint.h>
#include <sys/types.h>

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
  for(int i = 0; i < 32; i++)
    printf("GPR[%d]: 0x%08x\n", i, c->gpr[i]);

  if (user_handler) {
    Event ev = {0};
    switch (c->mcause) {
      case 1: c->mepc += 4;
      default: ev.event = c->mcause; break;
    }

    c = user_handler(ev, c);
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));

  // register event handler
  user_handler = handler;

  return true;
}

#define XLEN 4
#define CONTEXT_SIZE  ((NR_REGS + 3) * XLEN)
Context *kcontext(Area kstack, void (*entry)(void *), void *arg) {
  Context* context = (Context*) (kstack.end - CONTEXT_SIZE);
  context->gpr[2] = (uintptr_t) context;
  context->gpr[10] = (uintptr_t) arg;
  context->mepc = (uint32_t)entry;
  return  context;
}

void yield() {
#ifdef __riscv_e
  asm volatile("li a5, -1; ecall");
#else
  asm volatile("li a7, -1; ecall");
#endif
}

bool ienabled() {
  return false;
}

void iset(bool enable) {
}
