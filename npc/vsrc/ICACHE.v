module ICACHE(
  input  wire        clk,
  input  wire        rst,
  input  wire        flush,

  // IFU <-> ICACHE
  input  wire [31:0] ifu_req_addr,
  input  wire        ifu_req_valid,
  output wire        ifu_req_ready,
  output reg  [31:0] ifu_resp_data,
  output wire        ifu_resp_valid,
  input  wire        ifu_resp_ready,

  // ICACHE <-> AXI4 读通道
  output wire [31:0] araddr,
  output wire        arvalid,
  input  wire        arready,
  output wire [7:0]  arlen,
  output wire [2:0]  arsize,
  output wire [1:0]  arburst,
  input  wire [31:0] rdata,
  input  wire [1:0]  rresp,
  input  wire        rvalid,
  output wire        rready,
  input  wire        rlast
);

localparam [1:0] S_IDLE    = 2'd0,
                 S_MISS_REQ = 2'd1,
                 S_REFILL   = 2'd2,
                 S_RESP     = 2'd3;

reg [1:0] state;
reg [31:0] miss_base_addr_q;

assign ifu_req_ready = (state == S_IDLE);
assign ifu_resp_valid = (state == S_RESP);

assign araddr  = miss_base_addr_q;
assign arvalid = (state == S_MISS_REQ);
assign arlen   = 8'd0;      // 单拍读取，临时关闭 burst
assign arsize  = 3'b010;    // 4-byte
assign arburst = 2'b01;     // INCR burst

assign rready  = (state == S_REFILL);

always @(posedge clk) begin
  if (rst) begin
    state <= S_IDLE;
    ifu_resp_data <= 32'b0;
    miss_base_addr_q <= 32'b0;
  end else begin
    if (flush) begin
      // 非突发模式下不维护缓存，flush 不需要额外动作
    end

    case (state)
      S_IDLE: begin
        if (ifu_req_valid && ifu_req_ready) begin
          miss_base_addr_q <= {ifu_req_addr[31:2], 2'b00};
          state <= S_MISS_REQ;
        end
      end

      S_MISS_REQ: begin
        if (arvalid && arready) begin
          state <= S_REFILL;
        end
      end

      S_REFILL: begin
        if (rvalid && rready && (rresp == 2'b00)) begin
          ifu_resp_data <= rdata;
          state <= S_RESP;
        end
        if (rvalid && rready && (rresp != 2'b00) && rlast) begin
          state <= S_IDLE;
        end
      end

      S_RESP: begin
        if (ifu_resp_valid && ifu_resp_ready) begin
          state <= S_IDLE;
        end
      end

      default: begin
        state <= S_IDLE;
      end
    endcase
  end
end

endmodule
