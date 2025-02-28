module TypeIndicator (
	input [6:0] opcode,
	output [2:0] itype
);

MuxKeyWithDefault #(8, 7, 3) mkwd(itype, opcode, `NULL_TYPE, {
	7'b0110011, `R_TYPE,    // add, sub..
	7'b0010011, `I_TYPE,    // imm, addi..
	7'b1100111, `I_TYPE,    // Jalr
	7'b0000011, `I_TYPE,    // LW, LH, LB...
	7'b0110111, `U_TYPE,    // lui
	7'b0010111, `U_TYPE,    // auipc
	7'b1101111, `J_TYPE,    // jal
  7'b0100011, `S_TYPE     // sw, sh, sb
});

endmodule
