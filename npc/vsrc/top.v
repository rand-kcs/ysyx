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
  .src1(src1_gpr), .src2(src2_gpr),
  .dbg_rf(rf_dbg)
);

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


// ========== 信号声明 ==========
// IFU到ARBITER的连接信号
wire [31:0] ifu_araddr;
wire ifu_arvalid;
wire ifu_arready;
wire [31:0] ifu_rdata;
wire [1:0] ifu_rresp;
wire ifu_rvalid;
wire ifu_rready;

// ========== IFU实例化 ==========
IFU ifu(
  .clk(clk), 
  .rst(rst), 
  
  // AXI接口连接到ARBITER
  .araddr(ifu_araddr),
  .arvalid(ifu_arvalid),
  .arready(ifu_arready),
  
  .rdata(ifu_rdata),
  .rresp(ifu_rresp),
  .rvalid(ifu_rvalid),
  .rready(ifu_rready),
  
  // IFU没有写操作，所以写相关信号不连接或固定为0
  // 如果IFU模块有这些端口，需要接地
  // .awaddr(32'b0),
  // .awvalid(1'b0),
  // .awready(),
  // .wdata(32'b0),
  // .wstrb(4'b0),
  // .wvalid(1'b0),
  // .wready(),
  // .bresp(),
  // .bvalid(),
  // .bready(1'b0),
  
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

//    // ========== 声明共享的AXI4-Lite信号 ==========
//    // 这些信号将连接LSU（主设备）和DRAM2（从设备）
//    wire [31:0] araddr;    // 读地址
//    wire        arvalid;   // 读地址有效
//    wire        arready;   // 读地址就绪
//    
//    wire [31:0] rdata;     // 读数据
//    wire [1:0]  rresp;     // 读响应
//    wire        rvalid;    // 读数据有效
//    wire        rready;    // 读数据就绪
//    
//    wire [31:0] awaddr;    // 写地址
//    wire        awvalid;   // 写地址有效
//    wire        awready;   // 写地址就绪
//    
//    wire [31:0] wdata;     // 写数据
//    wire [3:0]  wstrb;     // 写字节使能
//    wire        wvalid;    // 写数据有效
//    wire        wready;    // 写数据就绪
//    
//    wire [1:0]  bresp;     // 写响应
//    wire        bvalid;    // 写响应有效
//    wire        bready;    // 写响应就绪

// LSU到ARBITER的连接信号
wire [31:0] lsu_araddr;
wire lsu_arvalid;
wire lsu_arready;
wire [31:0] lsu_rdata;
wire [1:0] lsu_rresp;
wire lsu_rvalid;
wire lsu_rready;
wire [31:0] lsu_awaddr;
wire lsu_awvalid;
wire lsu_awready;
wire [31:0] lsu_wdata;
wire [3:0] lsu_wstrb;
wire lsu_wvalid;
wire lsu_wready;
wire [1:0] lsu_bresp;
wire lsu_bvalid;
wire lsu_bready;

// ARBITER到DRAM2的连接信号
wire [31:0] arbiter_s_araddr;
wire arbiter_s_arvalid;
wire arbiter_s_arready;
wire [31:0] arbiter_s_rdata;
wire [1:0] arbiter_s_rresp;
wire arbiter_s_rvalid;
wire arbiter_s_rready;
wire [31:0] arbiter_s_awaddr;
wire arbiter_s_awvalid;
wire arbiter_s_awready;
wire [31:0] arbiter_s_wdata;
wire [3:0] arbiter_s_wstrb;
wire arbiter_s_wvalid;
wire arbiter_s_wready;
wire [1:0] arbiter_s_bresp;
wire arbiter_s_bvalid;
wire arbiter_s_bready;

// ========== DRAM2实例化 ==========
DRAM2 dram2(
  .clk(clk), 
  .rst(rst), 
  
  // read address path -->
  .araddr(arbiter_s_araddr),
  .arvalid(arbiter_s_arvalid),
  .arready(arbiter_s_arready),
  
  // read data path <--
  .rdata(arbiter_s_rdata),
  .rresp(arbiter_s_rresp),
  .rvalid(arbiter_s_rvalid),
  .rready(arbiter_s_rready),
  
  // write address path -->
  .awaddr(arbiter_s_awaddr),
  .awvalid(arbiter_s_awvalid),
  .awready(arbiter_s_awready),
  
  // write data path -->
  .wdata(arbiter_s_wdata),
  .wstrb(arbiter_s_wstrb),
  .wvalid(arbiter_s_wvalid),
  .wready(arbiter_s_wready),
  
  // write response path <--
  .bresp(arbiter_s_bresp),
  .bvalid(arbiter_s_bvalid),
  .bready(arbiter_s_bready)
);

// ========== LSU实例化 ==========
LSU lsu(
  .clk(clk), 
  .rst(rst), 
  
  .valid_in_exu(valid_exu_lsu), 
  .ready_out_exu(ready_lsu_exu),
  .valid_out_wbu(valid_lsu_wbu), 
  
  // AXI4-Lite接口 - 连接到ARBITER
  .araddr(lsu_araddr),     
  .arvalid(lsu_arvalid),   
  .arready(lsu_arready),   
  
  .rdata(lsu_rdata),       
  .rresp(lsu_rresp),       
  .rvalid(lsu_rvalid),     
  .rready(lsu_rready),     
  
  .awaddr(lsu_awaddr),     
  .awvalid(lsu_awvalid),   
  .awready(lsu_awready),   
  
  .wdata(lsu_wdata),       
  .wstrb(lsu_wstrb),       
  .wvalid(lsu_wvalid),     
  .wready(lsu_wready),     
  
  .bresp(lsu_bresp),       
  .bvalid(lsu_bvalid),     
  .bready(lsu_bready),     
  
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
  .alu_out(aluOut_exu),
  .wmask(wmask_exu),
  .wdata_exu(wdata_exu),
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
  .rdata_buf(rdata_w_lsu),
  .opcode_buf(opcode_lsu),
  .alu_out_buf(alu_out_lsu),


  .rresp_out(),
  .bresp_out()
);

// ========== ARBITER实例化 ==========
ARBITER arbiter(
  .clk(clk),
  .rst(rst),
  
  // 主设备0接口 (Master 0) - 分配给IFU
  // 读地址通道
  .m0_araddr(ifu_araddr),
  .m0_arvalid(ifu_arvalid),
  .m0_arready(ifu_arready),
  
  // 读数据通道
  .m0_rdata(ifu_rdata),
  .m0_rresp(ifu_rresp),
  .m0_rvalid(ifu_rvalid),
  .m0_rready(ifu_rready),
  
  // 写地址通道 - IFU没有写操作，接地
  .m0_awaddr(32'b0),
  .m0_awvalid(1'b0),
  .m0_awready(),  // 悬空，不连接
  
  // 写数据通道 - IFU没有写操作，接地
  .m0_wdata(32'b0),
  .m0_wstrb(4'b0),
  .m0_wvalid(1'b0),
  .m0_wready(),   // 悬空，不连接
  
  // 写响应通道 - IFU没有写操作，接地
  .m0_bresp(),    // 悬空，不连接
  .m0_bvalid(),   // 悬空，不连接
  .m0_bready(1'b0),
  
  // 主设备1接口 (Master 1) - 分配给LSU
  // 读地址通道
  .m1_araddr(lsu_araddr),
  .m1_arvalid(lsu_arvalid),
  .m1_arready(lsu_arready),
  
  // 读数据通道
  .m1_rdata(lsu_rdata),
  .m1_rresp(lsu_rresp),
  .m1_rvalid(lsu_rvalid),
  .m1_rready(lsu_rready),
  
  // 写地址通道
  .m1_awaddr(lsu_awaddr),
  .m1_awvalid(lsu_awvalid),
  .m1_awready(lsu_awready),
  
  // 写数据通道
  .m1_wdata(lsu_wdata),
  .m1_wstrb(lsu_wstrb),
  .m1_wvalid(lsu_wvalid),
  .m1_wready(lsu_wready),
  
  // 写响应通道
  .m1_bresp(lsu_bresp),
  .m1_bvalid(lsu_bvalid),
  .m1_bready(lsu_bready),
  
  // 从设备接口 (Slave) - 连接到DRAM2
  // 读地址通道
  .s_araddr(arbiter_s_araddr),
  .s_arvalid(arbiter_s_arvalid),
  .s_arready(arbiter_s_arready),
  
  // 读数据通道
  .s_rdata(arbiter_s_rdata),
  .s_rresp(arbiter_s_rresp),
  .s_rvalid(arbiter_s_rvalid),
  .s_rready(arbiter_s_rready),
  
  // 写地址通道
  .s_awaddr(arbiter_s_awaddr),
  .s_awvalid(arbiter_s_awvalid),
  .s_awready(arbiter_s_awready),
  
  // 写数据通道
  .s_wdata(arbiter_s_wdata),
  .s_wstrb(arbiter_s_wstrb),
  .s_wvalid(arbiter_s_wvalid),
  .s_wready(arbiter_s_wready),
  
  // 写响应通道
  .s_bresp(arbiter_s_bresp),
  .s_bvalid(arbiter_s_bvalid),
  .s_bready(arbiter_s_bready)
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
