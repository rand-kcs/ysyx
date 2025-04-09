/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <memory/paddr.h>

// this is not consistent with uint8_t
// but it is ok since we do not access the array directly
// static const uint32_t img [] = {
//   0x00000297,  // auipc t0,0
//   0x00028823,  // sb  zero,16(t0)
//   0x0102c503,  // lbu a0,16(t0)
//   0x00100073,  // ebreak (used as nemu_trap)
//   0xdeadbeef,  // some data
// };

// check jal valid;
static const uint32_t img [] = {
	0x00100093, // addi r1, r0, 1
	0x00108113, // addi r2, r1, 1
	0x0000a1b7, // lui x3, 10
	0x00001217, // auipc x4, 1<<12
	0x004002ef, // jal x5, 4
	0x00428367, // jalr x6, 4(x5)
	0x00100073, // ebreak;

};

static void restart() {
  /* Set the initial program counter. */
  cpu.pc = RESET_VECTOR;

  /* The zero register is always 0. */
  cpu.gpr[0] = 0;

  /* init mstatus csr for difftest  */
  cpu.mstatus = 0x1800;
}

void init_isa() {
  /* Load built-in image. */
  memcpy(guest_to_host(RESET_VECTOR), img, sizeof(img));

  /* Initialize this virtual computer system. */
  restart();
}
