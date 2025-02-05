module IDU (
	input [31:0] inst,
	output [4:0] rs1,
	output [4:0] rs2,
	output [4:0] rd,
	output [31:0] imm,
	output wen,
	output [2:0] func3,
	output [2:0] funcEU,
	output [1:0] amux1,
	output [1:0] amux2,
	output [6:0] opcode
);

assign func3 = inst[14:12];

assign rs1 = inst[19:15];
assign rs2 = inst[24:20];
assign rd = inst[11:7];

assign opcode = inst[6:0];

wire [2:0] itype;
TypeIndicator typeIc (opcode, itype);

// modulize a equaler ? 
assign wen =  itype === `I_TYPE | itype === `U_TYPE | itype === `J_TYPE;


// Make Immgen
ImmGenerator immG(itype, inst, imm);

MuxKeyWithDefault # (2, 3, 3) funcEU_MKWD(funcEU, itype, 3'b0, {
	`I_TYPE, func3,
	`U_TYPE, 3'b0
});


MuxKeyWithDefault # (5, 7, 2) amux1_MKWD(amux1, opcode, 2'b0, {
	7'b0110111, 2'd0, // lui asrc1 select 0 --U_type
	7'b0010011, 2'd1, // Normal addi, subi, xori.., select src1 I-type
	7'b1100111, 2'd1, // jalr, select reg src1  --I-type
	7'b0010111, 2'd2, // auipc  select pc --U_Type
	7'b1101111, 2'd2 // jal  select pc   --J_Type
});


MuxKeyWithDefault # (5, 7, 2) amux2_MKWD(amux2, opcode, 2'b0, {
	7'b0110111, 2'd2, // lui asrc2 select imm
	7'b0010011, 2'd2, // Normal addi, subi, xori.., select imm
  7'b1101111, 2'd2, // jal, select imm
	7'b1100111, 2'd2, // jalr , select imm
	7'b0010111, 2'd2  // auipc  select imm
});

endmodule
