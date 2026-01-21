`define NULL_TYPE 3'b000
`define R_TYPE 3'b001
`define I_TYPE 3'd2
`define S_TYPE 3'd3
`define B_TYPE 3'd4
`define U_TYPE 3'd5
`define J_TYPE 3'd6

module ysyx_24100030(
    // 系统信号
    input               clock,
    input               reset,
    input               io_interrupt,
    
    // AXI4 Master总线接口 - 完整AXI4协议
    // 写地址通道
    input               io_master_awready,
    output              io_master_awvalid,
    output [31:0]       io_master_awaddr,
    output [3:0]        io_master_awid,
    output [7:0]        io_master_awlen,
    output [2:0]        io_master_awsize,
    output [1:0]        io_master_awburst,
    
    // 写数据通道
    input               io_master_wready,
    output              io_master_wvalid,
    output [31:0]       io_master_wdata,
    output [3:0]        io_master_wstrb,
    output              io_master_wlast,
    
    // 写响应通道
    output              io_master_bready,
    input               io_master_bvalid,
    input  [1:0]        io_master_bresp,
    input  [3:0]        io_master_bid,
    
    // 读地址通道
    input               io_master_arready,
    output              io_master_arvalid,
    output [31:0]       io_master_araddr,
    output [3:0]        io_master_arid,
    output [7:0]        io_master_arlen,
    output [2:0]        io_master_arsize,
    output [1:0]        io_master_arburst,
    
    // 读数据通道
    output              io_master_rready,
    input               io_master_rvalid,
    input  [1:0]        io_master_rresp,
    input  [31:0]       io_master_rdata,
    input               io_master_rlast,
    input  [3:0]        io_master_rid,


    // ========== AXI4 Slave总线接口 ==========
    // 写地址通道
    output              io_slave_awready,
    input               io_slave_awvalid,
    input  [31:0]       io_slave_awaddr,
    input  [3:0]        io_slave_awid,
    input  [7:0]        io_slave_awlen,
    input  [2:0]        io_slave_awsize,
    input  [1:0]        io_slave_awburst,
    
    // 写数据通道
    output              io_slave_wready,
    input               io_slave_wvalid,
    input  [31:0]       io_slave_wdata,
    input  [3:0]        io_slave_wstrb,
    input               io_slave_wlast,
    
    // 写响应通道
    input               io_slave_bready,
    output              io_slave_bvalid,
    output [1:0]        io_slave_bresp,
    output [3:0]        io_slave_bid,
    
    // 读地址通道
    output              io_slave_arready,
    input               io_slave_arvalid,
    input  [31:0]       io_slave_araddr,
    input  [3:0]        io_slave_arid,
    input  [7:0]        io_slave_arlen,
    input  [2:0]        io_slave_arsize,
    input  [1:0]        io_slave_arburst,
    
    // 读数据通道
    input               io_slave_rready,
    output              io_slave_rvalid,
    output [31:0]       io_slave_rdata,
    output [1:0]        io_slave_rresp,
    output              io_slave_rlast,
    output [3:0]        io_slave_rid
    
    
    // 调试信号（保留原设计）
//    output reg [31:0]   inst,
//    output [31:0]       pc,
//    output              done,
//    output [31:0]       rf_dbg [31:0]
);

// 内部信号重命名（与原设计时钟/复位匹配）
wire clk = clock;
wire rst = reset;

// ========== AXI Slave接口默认值 ==========
// 根据提供的连接方式，为输出信号分配默认值

// 写地址通道 - slave准备接收写地址
assign io_slave_awready = 1'b0;  // 默认不准备好，因为我们没有实现slave功能

// 写数据通道 - slave准备接收写数据
assign io_slave_wready = 1'b0;   // 默认不准备好

// 写响应通道 - slave不发送响应（因为不处理写操作）
assign io_slave_bvalid = 1'b0;   // 响应无效
assign io_slave_bresp = 2'b00;   // OKAY响应（即使无效也赋默认值）
assign io_slave_bid = 4'b0;      // ID为0

// 读地址通道 - slave准备接收读地址
assign io_slave_arready = 1'b0;  // 默认不准备好

// 读数据通道 - slave不发送读数据
assign io_slave_rvalid = 1'b0;   // 读数据无效
assign io_slave_rdata = 32'b0;   // 读数据为0
assign io_slave_rresp = 2'b00;   // OKAY响应
assign io_slave_rlast = 1'b0;    // 不是最后一次传输
assign io_slave_rid = 4'b0;      // ID为0


initial begin
$dumpfile("build/wave.fst");
$dumpvars();
end

export "DPI-C" function ebreakYes;

function ebreakYes;
    ebreakYes = !|((inst_ifu_idu & 32'hfff0707f) ^ 32'h00100073);
endfunction

    reg [31:0]       pc;
    reg              done;
    reg [31:0]       rf_dbg [31:0];

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

// ========== IFU到ARBITER的连接信号 ==========
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
  
  .ready_in_idu(ready_idu_ifu), 
  .valid_out_idu(valid_ifu_idu), 
  
  // input
  .pc(pc), 
  .done(done), 
  
  // output
  .pc_buf(pc_ifu_idu),
  .inst(inst_ifu_idu)
);

//assign inst = inst_ifu_idu;

wire [31:0] pc_idu;
wire [4:0] rs1_idu;
wire [4:0] rs2_idu;
wire [4:0] rd_idu;
wire [31:0] imm_idu;
wire gpr_wen_idu;
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
    .gpr_wen_buf(gpr_wen_idu),
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

// ========== LSU到ARBITER的连接信号 ==========
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

// ========== LSU实例化 ==========
LSU lsu(
  .clk(clk), 
  .rst(rst), 
  
  .valid_in_exu(valid_exu_lsu), 
  .ready_out_exu(ready_lsu_exu),
  .valid_out_wbu(valid_lsu_wbu), 
  
  // AXI4接口 - 连接到ARBITER
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

// ========== ARBITER到顶层AXI接口的连接信号 ==========
wire [31:0] arb_to_axi_araddr;
wire        arb_to_axi_arvalid;
wire        arb_to_axi_arready;
wire [31:0] arb_to_axi_rdata;
wire [1:0]  arb_to_axi_rresp;
wire        arb_to_axi_rvalid;
wire        arb_to_axi_rready;
wire [31:0] arb_to_axi_awaddr;
wire        arb_to_axi_awvalid;
wire        arb_to_axi_awready;
wire [31:0] arb_to_axi_wdata;
wire [3:0]  arb_to_axi_wstrb;
wire        arb_to_axi_wvalid;
wire        arb_to_axi_wready;
wire [1:0]  arb_to_axi_bresp;
wire        arb_to_axi_bvalid;
wire        arb_to_axi_bready;

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
  
  // 写地址通道 - IFU没有写操作
  .m0_awaddr(32'b0),
  .m0_awvalid(1'b0),
  .m0_awready(),  // 悬空
  
  // 写数据通道 - IFU没有写操作
  .m0_wdata(32'b0),
  .m0_wstrb(4'b0),
  .m0_wvalid(1'b0),
  .m0_wready(),   // 悬空
  
  // 写响应通道 - IFU没有写操作
  .m0_bresp(),    // 悬空
  .m0_bvalid(),   // 悬空
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
  
  // 从设备接口 (Slave) - 连接到AXI接口
  // 读地址通道
  .s_araddr(arb_to_axi_araddr),
  .s_arvalid(arb_to_axi_arvalid),
  .s_arready(arb_to_axi_arready),
  
  // 读数据通道
  .s_rdata(arb_to_axi_rdata),
  .s_rresp(arb_to_axi_rresp),
  .s_rvalid(arb_to_axi_rvalid),
  .s_rready(arb_to_axi_rready),
  
  // 写地址通道
  .s_awaddr(arb_to_axi_awaddr),
  .s_awvalid(arb_to_axi_awvalid),
  .s_awready(arb_to_axi_awready),
  
  // 写数据通道
  .s_wdata(arb_to_axi_wdata),
  .s_wstrb(arb_to_axi_wstrb),
  .s_wvalid(arb_to_axi_wvalid),
  .s_wready(arb_to_axi_wready),
  
  // 写响应通道
  .s_bresp(arb_to_axi_bresp),
  .s_bvalid(arb_to_axi_bvalid),
  .s_bready(arb_to_axi_bready)
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

// ==============================================
// AXI4接口连接 - 将内部AXI4-Lite扩展到完整AXI4
// ==============================================

// 写地址通道连接
assign io_master_awvalid = arb_to_axi_awvalid;
assign io_master_awaddr  = arb_to_axi_awaddr;
assign io_master_awid    = 4'b0;      // 固定ID为0，单主设备
assign io_master_awlen   = 8'b0;      // 突发长度为1（AXI4-Lite模式）
assign io_master_awsize  = 3'b00;    // 4字节（32位）
assign io_master_awburst = 2'b0;     // 
assign arb_to_axi_awready = io_master_awready;

// 写数据通道连接
assign io_master_wvalid = arb_to_axi_wvalid;
assign io_master_wdata  = arb_to_axi_wdata;
assign io_master_wstrb  = arb_to_axi_wstrb;
assign io_master_wlast  = 1'b0;       // 单次传输，wlast始终为1
assign arb_to_axi_wready = io_master_wready;

// 写响应通道连接
assign io_master_bready = arb_to_axi_bready;
assign arb_to_axi_bvalid = io_master_bvalid;
assign arb_to_axi_bresp  = io_master_bresp;
// io_master_bid输入信号悬空

// 读地址通道连接
assign io_master_arvalid = arb_to_axi_arvalid;
assign io_master_araddr  = arb_to_axi_araddr;
assign io_master_arid    = 4'b0;      // 固定ID为0，单主设备
assign io_master_arlen   = 8'b0;      // 突发长度为1（AXI4-Lite模式）
assign io_master_arsize  = 3'b010;    // 4字节（32位）
assign io_master_arburst = 2'b00;     // 
assign arb_to_axi_arready = io_master_arready;

// 读数据通道连接
assign io_master_rready = arb_to_axi_rready;
assign arb_to_axi_rvalid = io_master_rvalid;
assign arb_to_axi_rresp  = io_master_rresp;
assign arb_to_axi_rdata  = io_master_rdata;
// io_master_rlast和io_master_rid输入信号悬空

endmodule
