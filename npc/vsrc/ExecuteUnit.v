module ExecuteUnit(
	input [31:0] src1,
	input [31:0] src2,
	input [31:0] imm,
	input [31:0] pc,
	input [9:0] funcEU,
	input [1:0] amux1,
	input [1:0] amux2,
	output [31:0] aluOut
);
	/*	
		EU level : src1 and src2 refer to the rs1 rs2 GPR result;
		ALU level: asrc1 and asrc2 refer to real manipulate target, like
		pc, imm ...
	*/
	wire [31:0] asrc1;
	wire [31:0] asrc2;

	MuxKeyWithDefault # (4, 2, 32) a1MKWD (asrc1, amux1, 32'b0, {
		2'd0, 32'b0,
		2'd1, src1,
		2'd2, pc,
		2'd3, 32'b0
	});
		
	MuxKeyWithDefault # (4, 2, 32) a2MKWD (asrc2, amux2, 32'b0, {
		2'd0, 32'b0,
		2'd1, src2,
		2'd2, imm,
		2'd3, 32'b0
	});


	ALU alu(asrc1, asrc2, funcEU, aluOut);

endmodule
