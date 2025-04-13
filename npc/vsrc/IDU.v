module IDU (
	input [31:0] inst,
	output [4:0] rs1,
	output [4:0] rs2,
	output [4:0] rd,
	output [31:0] imm,
	output wen /*verilator public*/,
	output [2:0] func3,
	output [9:0] funcEU,
	output [1:0] amux1,
	output [1:0] amux2,
	output [6:0] opcode,
  output valid,
  output mem_wen,
  output [7:0] wmask,

  output [11:0] csr_addr,
  output csr_wen,
  output is_ecall,
  output is_mret
);

assign func3 = inst[14:12];

wire [6:0] func7;
MuxKeyWithDefault # (6, 10, 7) func7_MKWD (func7,{opcode, func3}, inst[31:25], {
 {7'b0010011, 3'h0},  7'b0,
 {7'b0010011, 3'h4},  7'b0,
 {7'b0010011, 3'h6},  7'b0,
 {7'b0010011, 3'h7},  7'b0,
 {7'b0010011, 3'h2},  7'b0,
 {7'b0010011, 3'h3},  7'b0
 });

assign rs1 = inst[19:15];
assign rs2 = inst[24:20];
assign rd = inst[11:7];

assign opcode = inst[6:0];

wire [2:0] itype;
TypeIndicator typeIc (opcode, itype);

// modulize a equaler ? 
assign wen =  itype === `I_TYPE | itype === `U_TYPE | itype === `J_TYPE | itype ===`R_TYPE;
assign valid = opcode === 7'b0000011 | opcode === 7'b0100011; // load and store
assign mem_wen = opcode === 7'b0100011 ;

assign csr_addr = inst[31:20];
assign csr_wen = opcode === 7'b1110011 ;
assign is_ecall = inst === 32'h00000073;
assign is_mret = inst === 32'h30200073 ;


// Make Immgen
ImmGenerator immG(itype, inst, imm);

// itype => funcEU X!   opcode => funcEU ( func3 or add )
MuxKeyWithDefault # (2, 7, 10) funcEU_MKWD(funcEU, opcode, 10'b0, {
	7'b0110011, {func3, func7}, // add, sub, ...
	7'b0010011, {func3, func7} // addi, subi, ... the func7 has already updated.
  // default funcEU would be Add.
});

/*
* As for amux1
  2'd0 ->  0
  2'd1 ->  rs1
  2'd2 ->  pc
  2'd3 ->  0
*/
MuxKeyWithDefault # (9, 7, 2) amux1_MKWD(amux1, opcode, 2'b0, {
	7'b0110111, 2'd0, // lui asrc1 select 0 --U_type

	7'b0010011, 2'd1, // Normal addi, subi, xori.., select src1 I-type
	7'b1100111, 2'd1, // jalr, select reg src1  --I-type
  7'b0000011, 2'd1, // lw, lh, lb...
  7'b0100011, 2'd1, // sw, sb, sh
  7'b0110011, 2'd1, // add, sub, ...

	7'b0010111, 2'd2, // auipc  select pc --U_Type
	7'b1101111, 2'd2, // jal  select pc   --J_Type
	7'b1100011, 2'd2 //  branch, select pc
});

/*
* As for amux2
  2'd0 ->  0
  2'd1 ->  rs2
  2'd2 ->  imm
  2'd3 ->  0
*/

MuxKeyWithDefault # (9, 7, 2) amux2_MKWD(amux2, opcode, 2'b0, {
  7'b0110011, 2'd1, // add, sub, ...
	7'b0110111, 2'd2, // lui asrc2 select imm
	7'b0010011, 2'd2, // Normal addi, subi, xori.., select imm
  7'b1101111, 2'd2, // jal, select imm
	7'b1100111, 2'd2, // jalr , select imm
	7'b0010111, 2'd2,  // auipc  select imm
  7'b0000011, 2'd2,  // lw, lh, ...
  7'b0100011, 2'd2,  // sw, sh, sb
  7'b1100011, 2'd2   // branch
});

MuxKeyWithDefault # (3, 3, 8) wmask_MKWD(wmask, func3, 8'b0, {
  3'h0, 8'h1,
  3'h1, 8'h3,
  3'h2, 8'hf
});

endmodule
