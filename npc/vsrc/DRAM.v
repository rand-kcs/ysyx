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
  if(current_state === IDLE && next_state === WAIT_R) begin  // 等价于 状态恰好转移
    rdata <= pmem_read(araddr);
  end
end

endmodule
