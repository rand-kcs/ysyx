module ExecuteUnit(
	input [31:0] src1,
	input [31:0] imm,
	output [31:0] wdata
);
	assign wdata = src1 + imm;

endmodule
