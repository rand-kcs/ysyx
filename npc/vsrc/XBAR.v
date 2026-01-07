module XBAR(
  input clk,
  input rst,
  
  // ========== 主设备接口（来自ARBITER）==========
  // 读地址通道
  input [31:0]  arb_araddr,   // ARBITER输出的读地址
  input         arb_arvalid,  // ARBITER输出的读地址有效
  output        arb_arready,  // 返回给ARBITER的读地址就绪 (保持 wire)
  
  // 读数据通道
  output reg [31:0] arb_rdata,    // 返回给ARBITER的读数据 (改为 reg)
  output reg [1:0]  arb_rresp,    // 返回给ARBITER的读响应 (改为 reg)
  output reg        arb_rvalid,   // 返回给ARBITER的读数据有效 (改为 reg)
  input             arb_rready,   // ARBITER输出的读数据就绪
  
  // 写地址通道
  input [31:0]  arb_awaddr,   // ARBITER输出的写地址
  input         arb_awvalid,  // ARBITER输出的写地址有效
  output        arb_awready,  // 返回给ARBITER的写地址就绪 (保持 wire)
  
  // 写数据通道
  input [31:0]  arb_wdata,    // ARBITER输出的写数据
  input [3:0]   arb_wstrb,    // ARBITER输出的写字节使能
  input         arb_wvalid,   // ARBITER输出的写数据有效
  output        arb_wready,   // 返回给ARBITER的写数据就绪 (保持 wire)
  
  // 写响应通道
  output reg [1:0]  arb_bresp,    // 返回给ARBITER的写响应 (改为 reg)
  output reg        arb_bvalid,   // 返回给ARBITER的写响应有效 (改为 reg)
  input             arb_bready,   // ARBITER输出的写响应就绪
  
  // ========== 从设备接口1：DRAM ==========
  // 读地址通道
  output [31:0] dram_araddr,  // XBAR输出到DRAM的读地址
  output        dram_arvalid, // XBAR输出到DRAM的读地址有效
  input         dram_arready, // DRAM返回的读地址就绪
  
  // 读数据通道
  input [31:0]  dram_rdata,   // DRAM返回的读数据
  input [1:0]   dram_rresp,   // DRAM返回的读响应
  input         dram_rvalid,  // DRAM返回的读数据有效
  output reg    dram_rready,  // XBAR输出到DRAM的读数据就绪 (改为 reg)
  
  // 写地址通道
  output [31:0] dram_awaddr,  // XBAR输出到DRAM的写地址
  output        dram_awvalid, // XBAR输出到DRAM的写地址有效
  input         dram_awready, // DRAM返回的写地址就绪
  
  // 写数据通道
  output [31:0] dram_wdata,   // XBAR输出到DRAM的写数据
  output [3:0]  dram_wstrb,   // XBAR输出到DRAM的写字节使能
  output        dram_wvalid,  // XBAR输出到DRAM的写数据有效
  input         dram_wready,  // DRAM返回的写数据就绪
  
  // 写响应通道
  input [1:0]   dram_bresp,   // DRAM返回的写响应
  input         dram_bvalid,  // DRAM返回的写响应有效
  output reg    dram_bready,  // XBAR输出到DRAM的写响应就绪 (改为 reg)
  
  // ========== 从设备接口2：UART ==========
  // 读地址通道
  output [31:0] uart_araddr,  // XBAR输出到UART的读地址
  output        uart_arvalid, // XBAR输出到UART的读地址有效
  input         uart_arready, // UART返回的读地址就绪
  
  // 读数据通道
  input [31:0]  uart_rdata,   // UART返回的读数据
  input [1:0]   uart_rresp,   // UART返回的读响应
  input         uart_rvalid,  // UART返回的读数据有效
  output reg    uart_rready,  // XBAR输出到UART的读数据就绪 (改为 reg)
  
  // 写地址通道
  output [31:0] uart_awaddr,  // XBAR输出到UART的写地址
  output        uart_awvalid, // XBAR输出到UART的写地址有效
  input         uart_awready, // UART返回的写地址就绪
  
  // 写数据通道
  output [31:0] uart_wdata,   // XBAR输出到UART的写数据
  output [3:0]  uart_wstrb,   // XBAR输出到UART的写字节使能
  output        uart_wvalid,  // XBAR输出到UART的写数据有效
  input         uart_wready,  // UART返回的写数据就绪
  
  // 写响应通道
  input [1:0]   uart_bresp,   // UART返回的写响应
  input         uart_bvalid,  // UART返回的写响应有效
  output reg    uart_bready,  // XBAR输出到UART的写响应就绪 (改为 reg)
  
  // ========== 从设备接口3：CLINT ==========
  // 读地址通道
  output [31:0] clint_araddr, // XBAR输出到CLINT的读地址
  output        clint_arvalid, // XBAR输出到CLINT的读地址有效
  input         clint_arready, // CLINT返回的读地址就绪
  
  // 读数据通道
  input [31:0]  clint_rdata,  // CLINT返回的读数据
  input [1:0]   clint_rresp,  // CLINT返回的读响应
  input         clint_rvalid, // CLINT返回的读数据有效
  output reg    clint_rready, // XBAR输出到CLINT的读数据就绪 (改为 reg)
  
  // 写地址通道
  output [31:0] clint_awaddr, // XBAR输出到CLINT的写地址
  output        clint_awvalid, // XBAR输出到CLINT的写地址有效
  input         clint_awready, // CLINT返回的写地址就绪
  
  // 写数据通道
  output [31:0] clint_wdata,  // XBAR输出到CLINT的写数据
  output [3:0]  clint_wstrb,  // XBAR输出到CLINT的写字节使能
  output        clint_wvalid, // XBAR输出到CLINT的写数据有效
  input         clint_wready, // CLINT返回的写数据就绪
  
  // 写响应通道
  input [1:0]   clint_bresp,  // CLINT返回的写响应
  input         clint_bvalid, // CLINT返回的写响应有效
  output reg    clint_bready  // XBAR输出到CLINT的写响应就绪 (改为 reg)
);


// 地址映射参数定义
//localparam DRAM_BASE  = 32'h0000_0000;
//localparam DRAM_SIZE  = 32'h8000_0000;  // 2GB
//localparam DRAM_END   = DRAM_BASE + DRAM_SIZE - 1;

localparam UART_BASE  = 32'ha000_03f8;
localparam UART_SIZE  = 32'h0000_0004;  // 4B
localparam UART_END   = UART_BASE + UART_SIZE - 1;

localparam CLINT_BASE = 32'ha000_0048;
localparam CLINT_SIZE = 32'h0000_0008;  // 64KB
localparam CLINT_END  = CLINT_BASE + CLINT_SIZE - 1;


// 地址解码逻辑
// 根据地址范围决定路由到哪个从设备
function automatic [1:0] decode_slave(input [31:0] addr);
  if (addr >= UART_BASE && addr <= UART_END)
    decode_slave = 2'b01;  // UART
  else if (addr >= CLINT_BASE && addr <= CLINT_END)
    decode_slave = 2'b10;  // CLINT
  else //if (addr >= DRAM_BASE && addr <= DRAM_END)
    decode_slave = 2'b00;  // DRAM
 // else
 //   decode_slave = 2'b11;  // 地址错误
endfunction

// 读地址路由逻辑
wire [1:0] read_target = decode_slave(arb_araddr);

// 写地址路由逻辑  
wire [1:0] write_target = decode_slave(arb_awaddr);

// XBAR的核心逻辑：将来自ARBITER的请求路由到相应的从设备
// 这包括：读地址通道、读数据通道、写地址通道、写数据通道、写响应通道


// ========== 地址解码和信号路由 ==========
// 读地址通道路由
assign dram_araddr  = (read_target == 2'b00) ? arb_araddr : 32'b0;
assign dram_arvalid = (read_target == 2'b00) ? arb_arvalid : 1'b0;

assign uart_araddr  = (read_target == 2'b01) ? arb_araddr : 32'b0;
assign uart_arvalid = (read_target == 2'b01) ? arb_arvalid : 1'b0;

assign clint_araddr  = (read_target == 2'b10) ? arb_araddr : 32'b0;
assign clint_arvalid = (read_target == 2'b10) ? arb_arvalid : 1'b0;

// 从设备读地址就绪信号返回给ARBITER
assign arb_arready = (read_target == 2'b00) ? dram_arready :
                     (read_target == 2'b01) ? uart_arready :
                     (read_target == 2'b10) ? clint_arready : 1'b0;

// ========== 读数据通道返回逻辑 ==========
// 读数据从选定的从设备返回到ARBITER
always @(*) begin
  case (current_read_target)
    2'b00: begin
      arb_rdata = dram_rdata;
      arb_rresp = dram_rresp;
      arb_rvalid = dram_rvalid;
      dram_rready = arb_rready;
      uart_rready = 1'b0;
      clint_rready = 1'b0;
    end
    2'b01: begin
      arb_rdata = uart_rdata;
      arb_rresp = uart_rresp;
      arb_rvalid = uart_rvalid;
      dram_rready = 1'b0;
      uart_rready = arb_rready;
      clint_rready = 1'b0;
    end
    2'b10: begin
      arb_rdata = clint_rdata;
      arb_rresp = clint_rresp;
      arb_rvalid = clint_rvalid;
      dram_rready = 1'b0;
      uart_rready = 1'b0;
      clint_rready = arb_rready;
    end
    default: begin
      arb_rdata = 32'b0;
      arb_rresp = 2'b11; // SLVERR
      arb_rvalid = 1'b0;
      dram_rready = 1'b0;
      uart_rready = 1'b0;
      clint_rready = 1'b0;
    end
  endcase
end

// 写地址通道路由（类似读地址通道）
assign dram_awaddr  = (write_target == 2'b00) ? arb_awaddr : 32'b0;
assign dram_awvalid = (write_target == 2'b00) ? arb_awvalid : 1'b0;

assign uart_awaddr  = (write_target == 2'b01) ? arb_awaddr : 32'b0;
assign uart_awvalid = (write_target == 2'b01) ? arb_awvalid : 1'b0;

assign clint_awaddr  = (write_target == 2'b10) ? arb_awaddr : 32'b0;
assign clint_awvalid = (write_target == 2'b10) ? arb_awvalid : 1'b0;

assign arb_awready = (write_target == 2'b00) ? dram_awready :
                     (write_target == 2'b01) ? uart_awready :
                     (write_target == 2'b10) ? clint_awready : 1'b0;

// 写数据通道路由（与写地址通道目标相同）
assign dram_wdata  = (write_target == 2'b00) ? arb_wdata : 32'b0;
assign dram_wstrb  = (write_target == 2'b00) ? arb_wstrb : 4'b0;
assign dram_wvalid = (write_target == 2'b00) ? arb_wvalid : 1'b0;

assign uart_wdata  = (write_target == 2'b01) ? arb_wdata : 32'b0;
assign uart_wstrb  = (write_target == 2'b01) ? arb_wstrb : 4'b0;
assign uart_wvalid = (write_target == 2'b01) ? arb_wvalid : 1'b0;

assign clint_wdata  = (write_target == 2'b10) ? arb_wdata : 32'b0;
assign clint_wstrb  = (write_target == 2'b10) ? arb_wstrb : 4'b0;
assign clint_wvalid = (write_target == 2'b10) ? arb_wvalid : 1'b0;

assign arb_wready = (write_target == 2'b00) ? dram_wready :
                    (write_target == 2'b01) ? uart_wready :
                    (write_target == 2'b10) ? clint_wready : 1'b0;

// 写响应通道返回逻辑（类似读数据通道）
always @(*) begin
  case (current_write_target)
    2'b00: begin
      arb_bresp = dram_bresp;
      arb_bvalid = dram_bvalid;
      dram_bready = arb_bready;
      uart_bready = 1'b0;
      clint_bready = 1'b0;
    end
    2'b01: begin
      arb_bresp = uart_bresp;
      arb_bvalid = uart_bvalid;
      dram_bready = 1'b0;
      uart_bready = arb_bready;
      clint_bready = 1'b0;
    end
    2'b10: begin
      arb_bresp = clint_bresp;
      arb_bvalid = clint_bvalid;
      dram_bready = 1'b0;
      uart_bready = 1'b0;
      clint_bready = arb_bready;
    end
    default: begin
      arb_bresp = 2'b11; // SLVERR
      arb_bvalid = 1'b0;
      dram_bready = 1'b0;
      uart_bready = 1'b0;
      clint_bready = 1'b0;
    end
  endcase
end

// 状态寄存器，用于跟踪当前读/写事务的目标从设备
reg [1:0] current_read_target, current_write_target;

// 状态机或流水线寄存器更新逻辑
always @(posedge clk) begin
  if (rst) begin
    current_read_target <= 2'b00;
    current_write_target <= 2'b00;
  end else begin
    // 当读地址握手成功时，记录目标从设备
    if (arb_arvalid && arb_arready) begin
      current_read_target <= read_target;
    end
    
    // 当写地址握手成功时，记录目标从设备
    if (arb_awvalid && arb_awready) begin
      current_write_target <= write_target;
    end
    
    // 当读事务完成时，重置（可选）
    if (arb_rvalid && arb_rready) begin
      current_read_target <= 2'b00;
      current_write_target <= 2'b00;
    end
    
    // 当写事务完成时，重置（可选）
    if (arb_bvalid && arb_bready) begin
      current_read_target <= 2'b00;
      current_write_target <= 2'b00;
    end
  end
end

endmodule

