module DRAM2(
  input clk,
  input rst,

  // read address path  -->
  input reg [31:0] araddr,
  input arvalid,
  output arready,

  // read data path  <--
  output [31:0] rdata,
  output [1:0] rresp,
  output rvalid,
  input rready,

 // write address path  -->
 input [31:0] awaddr,
 input awvalid,
 output awready,

 // write data path  -->
 input [31:0] wdata,
 input [3:0] wstrb,
 input wvalid,
 output wready,

 // io status path  <--
 output [1:0] bresp,
 output bvalid,
 input bready
);

import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

// ========== 1. 状态定义与状态寄存器 ==========
// 使用独热码(one-hot)或二进制码(binary)，用parameter定义状态名
localparam [2:0] S_IDLE_R = 3'b00,
                 S_WAIT_RREADY = 3'b01,

                 S_IDLE_W =3'b10,
                 S_WAIT_BREADY = 3'b11;

reg [1:0] current_state_r, next_state_r; // 状态寄存器
reg [1:0] current_state_w, next_state_w; // 状态寄存器

// 时序逻辑部分：只在时钟沿更新状态
always @(posedge clk) begin
    if (rst) begin
        current_state_r <= S_IDLE_R; // 明确的复位状态
        current_state_w <= S_IDLE_W; // 明确的复位状态
    end else begin
        current_state_r <= next_state_r; // 状态转移
        current_state_w <= next_state_w; // 状态转移
    end
end

// ========== 2. 次态逻辑（组合逻辑） ==========
always @(*) begin
    // 默认值：防止生成锁存器，并指定一个安全状态（通常是保持）
    next_state = current_state;
    
    case(current_state_r) 
      S_IDLE_R:
        if(arvalid)
          next_state_r = S_WAIT_RREADY;
      S_WAIT_RREADY:
        if(rready)
          next_state_r = S_IDLE_R;
    endcase      

    case(current_state_w)
      S_IDLE_W:
        if(awvalid && wvalid)
          next_state_w = S_WAIT_BREADY;
      S_WAIT_BREADY:
        if(bready)
          next_state_w = S_IDLE_W;

end

// ========== 3. 输出逻辑 ==========
//摩尔型输出（输出仅取决于当前状态）
always @(*) begin
    arready = 1'b1;
    rvalid = 1'b0;

    wready = 1'b1;
    awready = 1'b1;
    bvalid = 1'b0;

    case (current_state_r)
      S_IDLE_R: begin
        arready = 1'b1;
        rvalid = 1'b0;
      end
      S_WAIT_RREADY:begin
        arready = 1'b0;
        rvalid = 1'b1;
      end
    endcase

    case (current_state_w)
      S_IDLE_W: begin
        wready = 1'b1;
        awready = 1'b1;
        bvalid = 1'b0;
      end
      S_WAIT_BREADY:begin
        wready = 1'b0;
        awready = 1'b0;
        bvalid = 1'b1;
      end
    endcase

end
 
reg [31:0] arbuf;
reg [31:0] awbuf;
reg [31:0] wbuf;
reg [3:0] wstrbuf,

// ======= 4. 模拟握手成功时， 内存进行的操作 注意是在下降沿，握手成功的中间
always @(negedge clock) begin
  if(arvalid && arready)
    arbuf <= araddr;
  if(rvalid)
    rdata <= pmem_read(araddr);

  if(awvalid && awready)
    awbuf <= awaddr;
  if(wvalid && wready) begin
    wbuf <= wdata;
    wstrbuf <= wstrb;
  end
  if(bvalid)
    pmem_write(waddr, wbuf, wstrbuf);

end


endmodule
