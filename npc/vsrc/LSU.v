module LSU(
  input clk,
  input rst,

  // AXI4-lite
  output reg [31:0] araddr,
  output arvalid,
  input arready,
  output [2:0] arsize,

  input [31:0] rdata,
  input [1:0] rresp,
  input rvalid,
  output rready,

  output [31:0] awaddr,
  output awvalid,
  input awready,

  output [31:0] wdata,
  output [3:0] wstrb,
  output wvalid,
  input wready,

  input [1:0] bresp,
  input bvalid,
  output bready,


  input valid_in_exu,
  output ready_out_exu,
 
  output valid_out_wbu,

  // 传递给 WBU
  input ben,
  input [31:0] pc,
  input [31:0] csr_out,
  input [6:0] opcode,
  
  input gpr_wen,
  input [4:0] rd,

  input csr_wen,
  input [31:0] csr_wdata,
  input [11:0] csr_waddr,
  input is_ecall,
  input is_mret,

  // LSU自己用的
  input mem_ren,
  input mem_wen,
  input [31:0] alu_out,
  input [7:0] wmask,
  input [31:0] wdata_exu,
  input [2:0] func3,

  output reg ben_buf,
  output reg [4:0] rd_buf,
  output reg [6:0] opcode_buf,

  output reg [31:0] pc_buf,
  output reg [31:0] csr_out_buf,
  output reg [31:0] alu_out_buf,
  output reg csr_wen_buf,
  output reg gpr_wen_buf,
  output reg [11:0] csr_waddr_buf,
  output reg [31:0] csr_wdata_buf,
  output is_ecall_buf,
  output is_mret_buf,

  output reg [31:0] rdata_buf,
  output reg [1:0] rresp_out,
  output reg [1:0] bresp_out,
  output lsu_valid_o,
  output lsu_pending_load
);

wire [31:0] raddr;// 同时也是 aluout
wire [31:0] waddr;
reg [31:0] addr;

assign raddr = alu_out;
assign waddr = alu_out;


// === 新增：极简版 mtime 计时器逻辑 ===
// 仅拦截 0x0200_0000 和 0x0200_0004 两个地址
wire is_mtime = (alu_out == 32'h0200_0000 || alu_out == 32'h0200_0004); 

reg [63:0] mtime;

// 维护 mtime 计数器，并处理软件写操作防止 AXI 死锁
always @(posedge clk) begin
    if (rst) begin
        mtime <= 64'd0;
    end else if (valid_in_exu && ready_out_exu && is_mtime && mem_wen) begin
        // 软件有可能写入 mtime，将其拦截并更新内部寄存器，不发往 AXI
        if (alu_out == 32'h0200_0000)
            mtime[31:0] <= wdata_exu;
        else if (alu_out == 32'h0200_0004)
            mtime[63:32] <= wdata_exu;
    end else begin
        // 正常计时，每拍加 1
        mtime <= mtime + 64'd1;
    end
end
// ==================================


// ========== 1. 状态定义与状态寄存器 ==========
// 使用独热码(one-hot)或二进制码(binary)，用parameter定义状态名
localparam [2:0] IDLE = 3'b00,
                 WAIT_ARREADY = 3'b01,
                 WAIT_RVALID = 3'b10,
                 
                 WAIT_WAWREADY= 3'b11,
                 WAIT_WREADY = 3'b100,
                 WAIT_AWREADY = 3'b101,
                 WAIT_BVALID=3'b110,

                 WAIT_WBU = 3'b111;

reg [2:0] next_state;
reg [2:0] current_state;
Reg #(3, IDLE) state(clk, rst, next_state, current_state, 1'b1);

// ========== 2. 次态逻辑（组合逻辑） ==========
always@(*) begin
  next_state = current_state;

  case (current_state)
    IDLE : begin
      if(valid_in_exu) begin
        // === 修改：如果是 mtime 地址，直接跳到 WBU，绕开 AXI 状态机 ===
        if(is_mtime)
          next_state = WAIT_WBU;
        else if(mem_ren) 
          next_state = WAIT_ARREADY;
        else if(mem_wen)
          next_state = WAIT_WAWREADY;
        else 
          next_state = WAIT_WBU;
      end
    end

    WAIT_ARREADY: begin
      if(arready) 
        next_state = WAIT_RVALID;
    end

    WAIT_RVALID: begin
      if(rvalid)
        next_state = WAIT_WBU;
    end

    WAIT_WBU: begin
      // 如果正在交接的当拍，EXU 发来了新的有效指令
      if (valid_in_exu) begin
        if(is_mtime)
          next_state = WAIT_WBU;       // 新指令也是 mtime，继续停在 WAIT_WBU 形成流水
        else if(mem_ren) 
          next_state = WAIT_ARREADY;   // 新指令是读内存
        else if(mem_wen)
          next_state = WAIT_WAWREADY;  // 新指令是写内存
        else 
          next_state = WAIT_WBU;       // 新指令也是普通 ALU 指令
      end 
      // 如果 EXU 没有新指令，老老实实回到 IDLE
      else begin
        next_state = IDLE;
      end
    end

    WAIT_WAWREADY: begin
      if(awready && wready)
        next_state = WAIT_BVALID;          
      else if(awready)
        next_state = WAIT_WREADY;
      else if(wready)
        next_state = WAIT_AWREADY;
    end

    WAIT_WREADY: begin
      if(wready) next_state = WAIT_BVALID;
    end

    WAIT_AWREADY: begin
      if(awready) next_state = WAIT_BVALID;
    end

    WAIT_BVALID:
      if(bvalid)
        next_state = WAIT_WBU;

    default: 
        next_state = IDLE; 
  endcase
end


// LSU/WB 流水寄存器的 valid 标志
reg lsu_valid;

// ========== 3. 输出逻辑 ==========
// ready/valid 语义：
// - 仅当 LSU 处于 IDLE（当前没有待处理指令）时，对 EXU 拉高 ready_out_exu
// - 当 LSU 内部已有一条指令且状态机到达 WAIT_WBU 时，对 WBU 拉高 valid_out_wbu
assign ready_out_exu = (current_state == IDLE  || current_state == WAIT_WBU);
assign valid_out_wbu = lsu_valid && (current_state == WAIT_WBU);
assign lsu_valid_o = lsu_valid;
assign lsu_pending_load = lsu_valid && lsu_is_load_buf && (current_state != WAIT_WBU);

// AXI 信号仍然由状态机驱动
always @(*) begin
    // 对于和 DRAM 的沟通
    arvalid = 1'b0;
    rready  = 1'b0;
    awvalid = 1'b0;
    wvalid  = 1'b0;
    bready  = 1'b0;

    case (current_state)
      WAIT_ARREADY: begin
        arvalid = 1'b1;
      end

      WAIT_RVALID: begin
        rready = 1'b1;
      end

      WAIT_WAWREADY: begin
        awvalid = 1'b1;
        wvalid  = 1'b1;
      end

      WAIT_WREADY: begin
      wvalid = 1'b1;  // AW 已经握手，只维持 WVALID
      end

      WAIT_AWREADY: begin
        awvalid = 1'b1; // W 已经握手，只维持 AWVALID
      end

      WAIT_BVALID: begin
        bready = 1'b1;
      end

      default: begin
        arvalid = 1'b0;
        rready  = 1'b0;
        awvalid = 1'b0;
        wvalid  = 1'b0;
        bready  = 1'b0;
      end
    endcase
end


reg [31:0] wdata_exu_buf;
reg [2:0] func3_buf;
reg lsu_is_load_buf;

// 接收来自 EXU 的请求，并在 WAIT_WBU 后清除 lsu_valid
always@(posedge clk) begin
  if (rst) begin
    lsu_valid <= 1'b0;
    lsu_is_load_buf <= 1'b0;
  end
  else begin
    // EXU -> LSU 握手成功：记录一条新的指令
    if (valid_in_exu && ready_out_exu) begin
      lsu_valid <= 1'b1;

      // Direct Pass 
      ben_buf       <= ben;
      opcode_buf    <= opcode;
      pc_buf        <= pc;
      rd_buf        <= rd;
      csr_out_buf   <= csr_out;
      alu_out_buf   <= alu_out;
      gpr_wen_buf   <= gpr_wen;
      csr_wen_buf   <= csr_wen;
      csr_waddr_buf <= csr_waddr;
      csr_wdata_buf <= csr_wdata;
      is_ecall_buf  <= is_ecall;
      is_mret_buf   <= is_mret;
      wdata_exu_buf <= wdata_exu;
      lsu_is_load_buf <= mem_ren;

      //later use
      func3_buf <= func3;

      // mtime 读旁路
      if (is_mtime && mem_ren) begin
        if      (alu_out == 32'h0200_0000) rdata_buf <= mtime[31:0];
        else if (alu_out == 32'h0200_0004) rdata_buf <= mtime[63:32];
        else                               rdata_buf <= 32'd0;
      end
    end
    // 一条指令在 WAIT_WBU 状态完成，对应的结果已经可以被 WBU 消费，下一拍回到 IDLE 后可接受新指令
    else if (current_state == WAIT_WBU) begin
     lsu_valid <= 1'b0;
     lsu_is_load_buf <= 1'b0;
    end
  end
end

assign araddr = alu_out_buf;
assign awaddr = alu_out_buf;

always @(*) begin
  case (func3_buf)
    3'b000: arsize = 3'b000 ;// LB
    3'b001: arsize = 3'b001 ;// LH
    3'b010: arsize = 3'b010 ;                        // LW
    3'b100:  arsize = 3'b000; // LBU
    3'b101:  arsize = 3'b001; // LHU
    default: arsize = 3'b010;                         // LW
  endcase
end

// rdata_w stands for treated after origin rdata from DRAM
wire [31:0] rdata_w;
RDATA_Processor rdata_processor(rdata, func3_buf, alu_out_buf[1:0], araddr, rdata_w);

WDATA_Processor wdata_processor(.wdata_origin(wdata_exu_buf), .func3(func3_buf), .addr_offset(alu_out_buf[1:0]), .wdata(wdata), .wstrb(wstrb));

always @(posedge clk) begin
  // 这里的 AXI 返回逻辑不动。对于 mtime 访问，rvalid 永远为低，不会覆盖 rdata_buf
  if(rvalid && rready) begin
    rdata_buf <= rdata_w;
    rresp_out <= rresp;
  end

  if(bready && bvalid)
    bresp_out <= bresp;
end

// ========== DEBUG_ON：访存性能计数器，仿照 IFU 用 $display 输出 ==========
`ifdef DEBUG_ON
  reg [31:0] debug_mem_timer;
  wire       load_in_progress   = (current_state == WAIT_ARREADY || current_state == WAIT_RVALID);
  wire       store_in_progress  = (current_state == WAIT_WAWREADY || current_state == WAIT_WREADY ||
                                  current_state == WAIT_AWREADY  || current_state == WAIT_BVALID);

  always @(posedge clk) begin
`ifdef DEBUG_ON_DETAIL
    $display("LSU Current State: : ", current_state);
`endif
    if (rst) begin
      debug_mem_timer <= 32'd0;
    end else begin
      if (current_state == IDLE) begin
        if (next_state == WAIT_ARREADY || next_state == WAIT_WAWREADY)
          debug_mem_timer <= 32'd0;
      end else if (load_in_progress) begin
        debug_mem_timer <= debug_mem_timer + 32'd1;
        if (rvalid && rready && rresp == 2'b00)
          $display("lsu load addr:%x, took %d cycles", araddr, debug_mem_timer + 32'd1);
      end else if (store_in_progress) begin
        debug_mem_timer <= debug_mem_timer + 32'd1;
        if (bvalid && bready && bresp == 2'b00)
          $display("lsu store addr:%x, took %d cycles", awaddr, debug_mem_timer + 32'd1);
      end
    end
  end
`endif

endmodule
