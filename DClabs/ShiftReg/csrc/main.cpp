#include <nvboard.h>
#include <Vtop.h>

static TOP_NAME dut;

void nvboard_bind_all_pins(TOP_NAME* top);

static void single_cycle() {
	Verilated::timeInc(1);
  dut.clk = 0; dut.eval();
	Verilated::timeInc(1);
  dut.clk = 1; dut.eval();
}

static void reset(int n) {
  dut.rst = 1;
  while (n -- > 0) single_cycle();
  dut.rst = 0;
}

int main() {
  nvboard_bind_all_pins(&dut);
  nvboard_init();
	Verilated::traceEverOn(true);

  reset(10);

  while(1) {
    nvboard_update();
    single_cycle();
  }
}
