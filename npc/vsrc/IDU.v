module IDU (
	input [31:0] inst,
	output [4:0] rs1,
	output [4:0] rs2,
	output [4:0] rd,
	output [31:0] imm,
	output wen,
	output [2:0] func3
);

assign func3 = inst[14:12];

assign rs1 = inst[19:15];
assign rs2 = inst[24:20];
assign rd = inst[11:7];
assign wen = !|(inst[6:0] ^ 7'b0010011);

assign imm = {{21{inst[31]}} , inst[30:20]};

endmodule
