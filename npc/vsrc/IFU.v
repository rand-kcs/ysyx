// IFU：取指状态机、缓存、通信信号，与 mem 模块沟通
module IFU (
  input clk,
  input rst,

  input [31:0] pc,           /// Communicate with PC_reg;
  input [31:0] redirect_pc,
  input flush,

  // AXI4-lite
  output reg [31:0] araddr,
  output arvalid,
  input arready,
  output [2:0] arsize,

  input [31:0] rdata,
  input [1:0] rresp,
  input rvalid,
  output rready,

  input ready_in_idu,         // Communicate with IDU;
  output valid_out_idu,       // To IDU
  output reg [31:0] pc_buf,
  output reg [31:0] inst
);

parameter IDLE       = 2'b00;
parameter WAIT_ADDR  = 2'b01;
parameter WAIT_DATA  = 2'b10;
parameter WAIT_IDU   = 2'b11;

reg [1:0] current_state;
reg [1:0] next_state;

// 独立取指指针：默认顺序按 PC+4 前推
reg [31:0] fetch_pc;
// 本次请求对应的PC（用于回填给IDU）
reg [31:0] req_pc;

// IF/ID valid 标志（与 IDU/EXU 风格一致）
reg if_valid;
// flush 时如果有在途请求，则丢弃一次返回数据
reg kill_resp;

assign arsize = 3'b010;
assign arvalid = (current_state == WAIT_ADDR);
assign rready  = (current_state == WAIT_DATA);
assign valid_out_idu = if_valid && ~flush;

always @(*) begin
  next_state = current_state;
  case (current_state)
    IDLE: begin
      next_state = WAIT_ADDR;
    end
    WAIT_ADDR: begin
      if (arready) begin
        next_state = WAIT_DATA;
      end
    end
    WAIT_DATA: begin
      if (rvalid) begin
        if (kill_resp) begin
          // 被 flush 杀掉的一次返回，直接回到 IDLE 重新取
          next_state = IDLE;
        end else begin
          next_state = WAIT_IDU;
        end
      end
    end
    WAIT_IDU: begin
      if (ready_in_idu) begin
        next_state = IDLE;
      end
    end
    default: begin
      next_state = IDLE;
    end
  endcase
end

`ifdef DEBUG_ON
reg [15:0] timer;
`endif

always @(posedge clk) begin
`ifdef DEBUG_ON_DETAIL
      $display("IFU Current State:",current_state);
`endif

  if (rst) begin
    current_state <= IDLE;
    araddr        <= 32'b0;
    pc_buf        <= 32'b0;
    inst          <= 32'b0;
    fetch_pc      <= pc;
    req_pc        <= 32'b0;
    if_valid      <= 1'b0;
    kill_resp     <= 1'b0;
  end else begin
    current_state <= next_state;

    // IFU 与其它流水段统一：flush 时仅清 valid；
    // 同时独立恢复 fetch 指针到 redirect 目标。
    if (flush) begin
      if_valid <= 1'b0;
      fetch_pc <= redirect_pc;
      if (current_state == WAIT_ADDR || current_state == WAIT_DATA) begin
        kill_resp <= 1'b1;
      end
    end

    // 发起一次取指请求
    if (current_state == IDLE && next_state == WAIT_ADDR) begin
      araddr   <= fetch_pc;
      req_pc   <= fetch_pc;
      fetch_pc <= fetch_pc + 32'd4;
`ifdef DEBUG_ON
      timer <= 16'd0;
`endif
    end

    // 收到取指数据：若是被 flush 的在途返回则丢弃
    if (current_state == WAIT_DATA && rvalid) begin
      if (kill_resp) begin
        kill_resp <= 1'b0;
      end else begin
        pc_buf   <= req_pc;
        inst     <= rdata;
        if_valid <= 1'b1;
`ifdef DEBUG_ON
        $display("fetch pc:%x, took %d cycles", req_pc, timer);
`endif
      end
    end

`ifdef DEBUG_ON
    if (current_state == WAIT_ADDR || current_state == WAIT_DATA) begin
      timer <= timer + 16'd1;
    end
`endif

    // 被 IDU 消费后清 valid
    if (if_valid && ready_in_idu) begin
      if_valid <= 1'b0;
    end
  end
end

endmodule
