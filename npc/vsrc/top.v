`define NULL_TYPE 3'b000
`define R_TYPE 3'b001
`define I_TYPE 3'd2
`define S_TYPE 3'd3
`define B_TYPE 3'd4
`define U_TYPE 3'd5
`define J_TYPE 3'd6

module top(
		input clk,
		input rst,
		output reg [31:0] inst,
		output [31:0] pc,
		output [31:0] rf_dbg [31:0]
);


import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

always @(negedge clk) begin
  inst <= pmem_read(pc);
end


wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rd;
wire [31:0] imm;
wire wen;
wire valid;
wire mem_wen;

wire [31:0] src1;
wire [31:0] src2;
wire [31:0] wdata;
wire [2:0] func3;
wire [6:0] opcode;
wire [9:0] funcEU;
wire [1:0] amux1;
wire [1:0] amux2;

wire [31:0] aluout;

wire [31:0] snpc;
wire [31:0] dnpc;
wire alu2wdata;

wire [31:0] rdata;
wire [31:0] rdata_w;

wire [7:0] wmask;
wire ben; // Branch Enable
wire jen; // Jump Enable

wire [11:0] csr_addr;
wire csr_wen;
wire [31:0] csr_out;
wire [31:0] csr_wdata;

wire is_ecall;
wire is_mret;


assign snpc = pc + 4;

wire [1:0] dnpc_select;
assign dnpc_select = {is_ecall|is_mret, ben|jen};

MuxKeyWithDefault #(4, 2, 32) dnpcMKWD(dnpc, dnpc_select, 32'b0, {
	2'b00, snpc,
	2'b01, aluout,
	2'b10, csr_out,
	2'b11, csr_out
});

PC_reg pc_reg(clk, rst, dnpc, pc);

// Decode Unit  -- RF -- EX   connected

IDU idu (inst, rs1, rs2, rd, imm, wen, func3, funcEU, amux1, amux2, opcode, valid, mem_wen, wmask, csr_addr, csr_wen, is_ecall, is_mret);
assign jen = (opcode === 7'b1101111 | opcode === 7'b1100111); // jal and jalr

MuxKeyWithDefault #(4, 7, 32) wdataMKWD(wdata, opcode, aluout, {
	7'b1101111, snpc,     //jal 
	7'b1100111, snpc,     //jalr 
  7'b0000011, rdata_w,  // lw, lh, lb, ...
  7'b1110011, csr_out  // csr..

  // unspecify opcode lead to default -- aluout
  // ( the inst with wen)
});

RegisterFile #(5, 32) RF(clk, wdata, rd, wen, rs1, rs2, src1, src2, rf_dbg);

ExecuteUnit eu(src1, src2, imm, pc, funcEU, amux1, amux2, aluout);

CSRs #(12, 32) csrs(clk, rst, csr_wdata, csr_addr, csr_wen, is_ecall, is_mret, pc, csr_out);
CSR_ALU csr_alu(func3,  csr_out, src1, csr_wdata);

BranchUnit be(src1, src2, func3, opcode, ben);

Mem memory(valid, aluout, mem_wen, aluout, wmask, src2, rdata);

RDATA_Processor rdata_processor(rdata, func3, rdata_w);

initial begin
	$display("[%0t]Not Tracing to logs/vlt_dump.fst", $time);
	//$dumpfile("logs/vlt_dump.fst");
	//$dumpvars();
end 

export "DPI-C" function ebreakYes;

function ebreakYes;
	ebreakYes =  !|((inst & 32'hfff0707f) ^ 32'h00100073);
endfunction


endmodule
