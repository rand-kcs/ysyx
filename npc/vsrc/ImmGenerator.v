module ImmGenerator(
	input [2:0] itype,
	input [31:0] inst,
	output [31:0] imm
);

MuxKeyWithDefault #(5, 3, 32) igMKWD(imm, itype, 32'b0, {
	// In riscv, the imm bit arrangement in
	// the inst indicate a more effective way of 
	// generating the whole imm thoughout the 6 format
	`I_TYPE, {{21{inst[31]}}, inst[30:20]},
	`U_TYPE, { inst[31:12], 12'b0 },
	`J_TYPE, { {12{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0 },
  `S_TYPE, { {20{inst[31]}}, inst[31:25], inst[11:7]},

	`NULL_TYPE, {inst[11:0] ,20'b0}// !! SOLVE WARNING!
});

endmodule
