module LSU(
  input clk,
  input rst,

  // AXI4-lite
  output reg [31:0] araddr,
  output arvalid,
  input arready,

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
  input [31:0] wdata,
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

  output reg [31:0] rdata_w_buf
);

wire [31:0] raddr;// 同时也是 aluout
wire [31:0] waddr;

assign raddr = alu_out;
assign waddr = alu_out;

import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

parameter IDLE       = 2'b00;
parameter WAIT_READY = 2'b01;

reg [1:0] next_state;
reg [1:0] current_state;

// state trans reg;
Reg #(2, IDLE) state(clk, rst, next_state, current_state, 1'b1);

// state change logic : next_state
always@(*) begin
  next_state = current_state;
  case (current_state)
    IDLE : begin
      if(valid_in_exu) begin
        next_state = WAIT_READY;
      end
    end
    WAIT_READY : begin
        next_state = IDLE; 
    end
    default: 
        next_state = IDLE; 
  endcase
end

// output rely on specific state;
assign ready_out_exu = current_state === IDLE;
assign valid_out_wbu = current_state === WAIT_READY;

always@(posedge clk) begin
  if (current_state === IDLE && next_state === WAIT_READY) begin  // 状态恰好转移
    rdata_w_buf <= rdata_w;

    // Direct Pass 
    ben_buf <= ben;
    opcode_buf <= opcode;
    pc_buf <= pc;
    rd_buf <= rd;
    csr_out_buf <= csr_out;
    alu_out_buf <= alu_out;
    gpr_wen_buf <=  gpr_wen;
    rd_buf <= rd;
    csr_wen_buf <= csr_wen;
    csr_waddr_buf <= csr_waddr;
    csr_wdata_buf <= csr_wdata;
    is_ecall_buf <= is_ecall;
    is_mret_buf <= is_mret;
  end
end


reg [31:0] rdata;
wire [31:0] rdata_w;





always @(mem_ren, raddr, waddr, wdata, wmask, mem_wen) begin
  if (valid_in_exu) begin
    if(mem_ren) begin // 有读写请求时
      rdata <= pmem_read(raddr);
    end
    if (mem_wen) begin // 有写请求时
      pmem_write(waddr, wdata, wmask);
    end
  end
  else begin
    rdata <= 0;
  end
end


RDATA_Processor rdata_processor(rdata, func3, rdata_w);

endmodule
