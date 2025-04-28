// each DONE sig stands for a inst done, except the fitst reset;
// 实例化一个 IFU， 包括 PC 寄存器， 缓存， 通信信号， 与 mem 模块沟通
module IFU (
  input clk,
  input rst,

  input [31:0]  pc,           /// Communicate with PC_reg;
  input done,
  //output reg ready_out_pc,

  input ready_in_idu,         // Communicate with IDU;
  output valid_out_idu,       // From IDU  
  output reg [31:0] pc_buf,
  output reg [31:0] inst      // To IDU     
);

typedef enum logic [1:0] {
  IDLE      = 2'b00,
  WAIT_READY = 2'b01,
} state_t;

wire [1:0] next_state;
wire [1:0] current_state;

// state trans reg;
Reg #(2, IDLE) state(clk, rst, next_state, current_state, 1'b1);


// the state trans logic
always@(*) begin
  next_state = current_state;
  case (current_state)
    IDLE : begin
      if(done) begin
        next_state = WAIT_READY;
      end
    end
    WAIT_READY : begin
      if(ready_in_idu) begin
        next_state = IDLE; 
      end
    end
end

// output reley on state
assign valid_out_idu  = current_state === WAIT_READY ;
always@(posedge clk) begin
  if(current_state === IDLE && next_state === WAIT_READY) begin  // 等价于 状态恰好转移
    pc_buf <= pc;
    inst <= pmem_read(pc);
  end
end


endmodule
