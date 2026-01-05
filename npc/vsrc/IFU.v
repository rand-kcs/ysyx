// each DONE sig stands for a inst done, except the fitst reset;
// 实例化一个 IFU， 包括 PC 寄存器， 缓存， 通信信号， 与 mem 模块沟通
module IFU (
  input clk,
  input rst,

  input [31:0]  pc,           /// Communicate with PC_reg;
  input done,
  //output reg ready_out_pc,
  
  // AXI4-lite
  output reg [31:0] araddr,
  output arvalid,
  input arready,

  input [31:0] rdata,
  input [1:0] rresp,
  input rvalid,
  output rready,

  input ready_in_idu,         // Communicate with IDU;
  output valid_out_idu,       // From IDU  
  output reg [31:0] pc_buf,
  output reg [31:0] inst      // To IDU     
);


parameter IDLE       = 2'b00;
parameter WAIT_ADDR  = 2'b01;
parameter WAIT_DATA  = 2'b10;
parameter WAIT_IDU   = 2'b11;

reg [1:0] next_state;
reg [1:0] current_state;

// state trans reg;
Reg #(2, IDLE) state(clk, rst, next_state, current_state, 1'b1);


// the state trans logic
always@(*) begin
  next_state = current_state;
  case (current_state)
    IDLE : begin
      if(done) begin
        next_state = WAIT_ADDR;
      end
    end
    WAIT_ADDR : begin
      if(arready) begin
        next_state = WAIT_DATA; 
      end
    end
    WAIT_DATA : begin
      if(rvalid) begin
        next_state = WAIT_IDU; 
      end
    end
    WAIT_IDU : begin
      if(ready_in_idu) begin
        next_state = IDLE; 
      end
    end
    default: 
        next_state = IDLE; 
  endcase
end

// output reley on state
assign valid_out_idu  = current_state === WAIT_IDU ;
assign arvalid = current_state === WAIT_ADDR;
assign rready = current_state === WAIT_DATA;

always@(posedge clk) begin
  if(current_state === IDLE && next_state === WAIT_ADDR) begin  // 等价于 状态恰好转移
    pc_buf <= pc;
    araddr <= pc;
  end
  else if(current_state === WAIT_DATA && next_state === WAIT_IDU) begin  // 等价于 状态恰好转移 握手成功
    inst <= rdata;
  end
end


endmodule
