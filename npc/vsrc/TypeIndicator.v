module TypeIndicator (
	input [6:0] opcode,
	output [2:0] itype
);

MuxKeyWithDefault #(5, 7, 3) mkwd(itype, opcode, `NULL_TYPE, {
	7'b0010011, `I_TYPE, // imm, addi..
	7'b1100111, `I_TYPE, // Jalr
	7'b0110111, `U_TYPE,
	7'b0010111, `U_TYPE,
	7'b1101111, `J_TYPE  // jal
});

endmodule
