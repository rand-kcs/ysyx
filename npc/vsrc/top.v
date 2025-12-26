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
    output done,
		output [31:0] rf_dbg [31:0]
);


initial begin
$dumpfile("wave.fst");
$dumpvars();
end



import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

export "DPI-C" function ebreakYes;

function ebreakYes;
	ebreakYes =  !|((inst & 32'hfff0707f) ^ 32'h00100073);
endfunction

wire [31:0] dnpc;
wire [4:0] rd_wbu;
wire [31:0] gpr_wdata_wbu;
wire csr_wen_wbu;
wire valid_wbu;
wire [11:0] csr_waddr_wbu;
wire [31:0] csr_wdata_wbu;
wire is_ecall_wbu;
wire is_mret_wbu;
wire [31:0] pc_wbu;
wire gpr_wen_wbu;
 
wire [31:0] pc_ifu_idu, pc_idu_exu, pc_exu_lsu, pc_lsu_wbu;
wire [31:0] inst_ifu_idu;

wire ready_idu_ifu, ready_exu_idu, ready_lsu_exu, ready_wbu_lsu;
wire valid_ifu_idu, valid_idu_exu, valid_exu_lsu, valid_lsu_wbu;

PC_reg pc_reg(.clk(clk), .rst(rst), .valid_wbu(valid_wbu), .dnpc(dnpc), .pc(pc), .done(done));

wire [4:0] rs1_idu, rs2_idu, rd_idu_exu;
wire [31:0] src1_gpr, src2_gpr;
wire [31:0] csr_out_idu;
RegisterFile #(5, 32) gprs(.clk(clk), .wdata(gpr_wdata_wbu),  .valid_wbu(valid_wbu),
  .waddr(rd_wbu), .wen(gpr_wen_wbu), .rs1(rs1_idu), .rs2(rs2_idu), 
  .src1(src1_gpr), .src2(src2_gpr), .dbg_rf(rf_dbg));

CSRs #(12, 32) csrs(
  .clk(clk), .rst(rst), 
  .valid_wbu(valid_wbu),

  .waddr(csr_waddr_wbu),
  .wdata(csr_wdata_wbu),
  .wen(csr_wen_wbu),
  .is_ecall_wbu(is_ecall_wbu),
  .is_mret_wbu(is_mret_wbu),
  .pc(pc_wbu),

  .is_ecall_idu(is_ecall_idu),
  .is_mret_idu(is_mret_idu),
  .raddr(csr_waddr_idu),
  .data(csr_out_idu)
);


wire [31:0] araddr_ifu;
wire arvalid_ifu;
wire arready_ifu;
wire [31:0] rdata_ifu;
wire [1:0] rresp_ifu;
wire rvalid_ifu;
wire rready_ifu;

DRAM mem_inst(
  .clk(clk), 
  .rst(rst),

  .araddr(araddr_ifu),
  .arvalid(arvalid_ifu),
  .arready(arready_ifu),

  .rdata(rdata_ifu),
  .rresp(rresp_ifu),
  .rvalid(rvalid_ifu),
  .rready(rready_ifu)
);

IFU ifu(
  .clk(clk), 
  .rst(rst), 

  .araddr(araddr_ifu),
  .arvalid(arvalid_ifu),
  .arready(arready_ifu),

  .rdata(rdata_ifu),
  .rresp(rresp_ifu),
  .rvalid(rvalid_ifu),
  .rready(rready_ifu),

  .ready_in_idu(ready_idu_ifu), 
  .valid_out_idu(valid_ifu_idu), 

  // input
  .pc(pc), 
  .done(done), 

  // output
  .pc_buf(pc_ifu_idu),
  .inst(inst_ifu_idu)
);
assign inst = inst_ifu_idu;

  wire [31:0] pc_idu;
	wire [4:0] rs1_idu;
	wire [4:0] rs2_idu;
	wire [4:0] rd_idu;
	wire [31:0] imm_idu;
	wire gpr_wen_idu ;
	wire [2:0] func3_idu;
	wire [9:0] funcEU_idu;
	wire [1:0] amux1_idu;
	wire [1:0] amux2_idu;
	wire [6:0] opcode_idu;
  wire mem_ren_idu;
  wire mem_wen_idu;
  wire [7:0] wmask_idu;

  wire [11:0] csr_waddr_idu;
  wire csr_wen_idu;
  wire is_ecall_idu;
  wire is_mret_idu;

IDU idu(
  .clk(clk), 
  .rst(rst), 

  .ready_in_exu(ready_exu_idu), 
  .valid_out_exu(valid_idu_exu), 

  .valid_in_ifu(valid_ifu_idu), 
  .ready_out_ifu(ready_idu_ifu), 

  .pc(pc_ifu_idu),
  .inst(inst_ifu_idu),

  // output
  .pc_buf(pc_idu),
	.rs1_buf(rs1_idu),
	.rs2_buf(rs2_idu),
	.rd_buf(rd_idu),
	.imm_buf(imm_idu),
	.gpr_wen_buf(gpr_wen_idu) ,
	.func3_buf(func3_idu),
	.funcEU_buf(funcEU_idu),
	.amux1_buf(amux1_idu),
	.amux2_buf(amux2_idu),
	.opcode_buf(opcode_idu),
  .mem_ren_buf(mem_ren_idu),
  .mem_wen_buf(mem_wen_idu),
  .wmask_buf(wmask_idu),

  .csr_addr_buf(csr_waddr_idu),
  .csr_wen_buf(csr_wen_idu),
  .is_ecall_buf(is_ecall_idu),
  .is_mret_buf(is_mret_idu)
);


wire ben_exu;
wire gpr_wen_exu;
wire [4:0] rd_exu;
wire csr_wen_exu;
wire [11:0] csr_waddr_exu;
wire [31:0] csr_out_exu;

wire [2:0] func3_exu;
wire mem_ren_exu;
wire [31:0] wdata_exu;
wire [7:0] wmask_exu;
wire mem_wen_exu;

wire ben_exu;
wire [31:0] aluOut_exu;
wire [31:0] csr_wdata_exu;
wire [31:0] pc_exu;
wire [6:0] opcode_exu;

wire is_ecall_exu;
wire is_mret_exu;

EXU exu(
  .clk(clk), 
  .rst(rst), 

  .ready_in_lsu(ready_lsu_exu), 
  .valid_out_lsu(valid_exu_lsu),  

  .valid_in_idu(valid_idu_exu), 
  .ready_out_idu(ready_exu_idu), 

  .func3(func3_idu),
  .opcode(opcode_idu),
  .imm(imm_idu),
  .pc(pc_idu),
  .funcEU(funcEU_idu),
  .amux1(amux1_idu),
  .amux2(amux2_idu),
  .is_ecall(is_ecall_idu),
  .is_mret(is_mret_idu),

  .src1(src1_gpr), 
  .src2(src2_gpr),
  .csr_out(csr_out_idu),

  .wmask(wmask_idu),
  .mem_wen(mem_wen_idu),
  .mem_ren(mem_ren_idu),
  
  .gpr_wen(gpr_wen_idu),
  .rd(rd_idu),
  .csr_wen(csr_wen_idu),
  .csr_waddr(csr_waddr_idu),



  .ben_buf(ben_exu),
  .gpr_wen_buf(gpr_wen_exu),
  .rd_buf(rd_exu),
  .csr_wen_buf(csr_wen_exu),
  .csr_waddr_buf(csr_waddr_exu),

  .is_ecall_buf(is_ecall_exu),
  .is_mret_buf(is_mret_exu),
  
  .func3_buf(func3_exu),
  .mem_ren_buf(mem_ren_exu),
  .wdata_buf(wdata_exu),
  .wmask_buf(wmask_exu),
  .mem_wen_buf(mem_wen_exu),
  .pc_buf(pc_exu),
  .csr_out_buf(csr_out_exu),
  .opcode_buf(opcode_exu),
 
  .aluOut_buf(aluOut_exu),
  .csr_wdata_buf(csr_wdata_exu)

);

wire ben_lsu;
wire [31:0] pc_lsu;
wire [31:0] csr_out_lsu;
wire csr_wen_lsu;
wire gpr_wen_lsu;
wire [11:0] csr_waddr_lsu;
wire [31:0] csr_wdata_lsu;
wire [31:0] rdata_w_lsu;
wire [6:0] opcode_lsu;
wire [4:0] rd_lsu;
wire [31:0] alu_out_lsu;
wire is_ecall_lsu;
wire is_mret_lsu;


LSU lsu(
  .clk(clk), 
  .rst(rst), 

  .valid_in_exu(valid_exu_lsu), 
  .ready_out_exu(ready_lsu_exu),

  .valid_out_wbu(valid_lsu_wbu), 


  .ben(ben_exu),
  .pc(pc_exu),
  .csr_out(csr_out_exu),
  .opcode(opcode_exu),
  
  .gpr_wen(gpr_wen_exu),
  .rd(rd_exu),

  .csr_wen(csr_wen_exu),
  .csr_waddr(csr_waddr_exu),
  .csr_wdata(csr_wdata_exu),
  .is_ecall(is_ecall_exu),
  .is_mret(is_mret_exu),

  // LSU自己用的
  .mem_ren(mem_ren_exu),
  .mem_wen(mem_wen_exu),
  .alu_out(aluOut_exu), // 同时也是 aluout
  .wmask(wmask_exu),
  .wdata(wdata_exu),
  .func3(func3_exu),
  .rd_buf(rd_lsu),

  // output
  .ben_buf(ben_lsu),
  .pc_buf(pc_lsu),
  .gpr_wen_buf(gpr_wen_lsu),
  .csr_out_buf(csr_out_lsu),
  .csr_wen_buf(csr_wen_lsu),
  .is_ecall_buf(is_ecall_lsu),
  .is_mret_buf(is_mret_lsu),
  .csr_waddr_buf(csr_waddr_lsu),
  .csr_wdata_buf(csr_wdata_lsu),
  .rdata_w_buf(rdata_w_lsu),
  .opcode_buf(opcode_lsu),
  .alu_out_buf(alu_out_lsu)
);

WBU wbu(
  .valid_in_lsu(valid_lsu_wbu), 

  .ben(ben_lsu),
  .opcode(opcode_lsu),
  .pc(pc_lsu),
  .alu_out(alu_out_lsu),
  .csr_out(csr_out_lsu),
  .rdata_w(rdata_w_lsu),
  .gpr_wen(gpr_wen_lsu),
  .rd(rd_lsu),
  .csr_wen(csr_wen_lsu),
  .csr_waddr(csr_waddr_lsu),
  .csr_wdata(csr_wdata_lsu),
  .is_ecall(is_ecall_lsu),
  .is_mret(is_mret_lsu),

  .gpr_wen_buf(gpr_wen_wbu),
  .rd_buf(rd_wbu), 
  .gpr_wdata(gpr_wdata_wbu), 
  .is_ecall_buf(is_ecall_wbu),
  .is_mret_buf(is_mret_wbu),

  .dnpc(dnpc),
  .pc_buf(pc_wbu),

  .csr_wen_buf(csr_wen_wbu),
  .csr_waddr_buf(csr_waddr_wbu),
  .csr_wdata_buf(csr_wdata_wbu),

  .valid_out_wbu(valid_wbu)
);

endmodule
