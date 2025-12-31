module DRAM(
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
  input rready

//  // write address path  -->
 // input [31:0] awaddr,
 // input awvalid,
 // output awready,

 // // write data path  -->
 // input [31:0] wdata,
 // input [3:0] wstrb,
 // input wvalid,
 // output wready,

 // // io status path  <--
 // output [1:0] bresp,
 // output bvalid,
 // input bready
);

import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

parameter IDLE       = 2'b00;
// Wate IFU to recive rdata : the R road;
parameter WAIT_R  = 2'b01;
// RANDOM DELAY STATUS
parameter DELAY  = 2'b10;

// ==========  随机延迟控制 ==========
reg [2:0] delay_counter;     // 延迟计数器（0-7周期）
reg [2:0] random_delay;      // 随机延迟值（可来自LFSR或外部）

// 伪随机数生成器（简易LFSR，实际可用更复杂的）
reg [7:0] lfsr;
always @(posedge clk) begin
    if (rst) begin
        lfsr <= 8'hA9;
    end else begin
        lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
    end
end




reg [1:0] next_state;
reg [1:0] current_state;

// state trans reg;
Reg #(2, IDLE) state(clk, rst, next_state, current_state, 1'b1);

// output reley on state
assign arready = current_state === IDLE;
assign rvalid = current_state === WAIT_R;

// state transfer 
always@(*) begin
  next_state = current_state;
  case (current_state)
    IDLE : begin
      if(arvalid) begin
        next_state = DELAY;
        random_delay = lfsr[2:0];
        delay_counter = random_delay;
      end
    end

    DELAY : begin
      delay_counter = delay_counter - 1;
      if (delay_counter == 0) begin
         next_state = WAIT_R;
      end
    end

    WAIT_R : begin
      if(rready) begin
        next_state = IDLE; 
      end
    end
    default: 
        next_state = IDLE; 
  endcase
end

//behavior reley on state transfer
always@(posedge clk) begin
    rdata <= pmem_read(araddr);
end

endmodule
