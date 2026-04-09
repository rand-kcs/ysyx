module ICACHE #(
  parameter ICACHE_BURST_EN = 1,
  parameter LINE_NUM        = 64,
  parameter WORDS_PER_LINE  = 4
)(
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

localparam LINE_IDX_W = $clog2(LINE_NUM);
localparam LINE_OFF_W = $clog2(WORDS_PER_LINE);
localparam TAG_W      = 32 - LINE_IDX_W - LINE_OFF_W - 2;
localparam integer LAST_BEAT_INT = WORDS_PER_LINE - 1;

localparam [1:0] S_IDLE    = 2'd0,
                 S_MISS_REQ = 2'd1,
                 S_REFILL   = 2'd2,
                 S_RESP     = 2'd3;

reg [1:0] state;
reg [31:0] miss_base_addr_q;

// burst 模式使用的 cache arrays
reg [TAG_W-1:0] tag_array [0:LINE_NUM-1];
reg             valid_array [0:LINE_NUM-1];
reg [31:0]      data_array [0:LINE_NUM-1][0:WORDS_PER_LINE-1];
reg [LINE_OFF_W-1:0] refill_beat_cnt;
reg [LINE_OFF_W-1:0] req_word_off_q;
reg [LINE_IDX_W-1:0] req_index_q;
reg [TAG_W-1:0]      req_tag_q;
integer i, j;

wire [LINE_IDX_W-1:0] req_index    = ifu_req_addr[LINE_OFF_W + LINE_IDX_W + 1:LINE_OFF_W + 2];
wire [LINE_OFF_W-1:0] req_word_off = ifu_req_addr[LINE_OFF_W + 1:2];
wire [TAG_W-1:0]      req_tag      = ifu_req_addr[31:LINE_OFF_W + LINE_IDX_W + 2];
wire                  hit          = valid_array[req_index] && (tag_array[req_index] == req_tag);

// ========== 简易命中统计 ==========
reg [31:0] access_cnt;
reg [31:0] hit_cnt;
reg [31:0] miss_cnt;

assign ifu_req_ready = (state == S_IDLE);
assign ifu_resp_valid = (state == S_RESP);

assign araddr  = miss_base_addr_q;
assign arvalid = (state == S_MISS_REQ);
assign arlen   = ICACHE_BURST_EN ? (WORDS_PER_LINE - 1) : 8'd0;
assign arsize  = 3'b010;    // 4-byte
assign arburst = 2'b01;     // INCR burst

assign rready  = (state == S_REFILL);

always @(posedge clk) begin
  if (rst) begin
    state <= S_IDLE;
    ifu_resp_data <= 32'b0;
    miss_base_addr_q <= 32'b0;
    refill_beat_cnt <= {LINE_OFF_W{1'b0}};
    req_word_off_q <= {LINE_OFF_W{1'b0}};
    req_index_q <= {LINE_IDX_W{1'b0}};
    req_tag_q <= {TAG_W{1'b0}};
    access_cnt <= 32'b0;
    hit_cnt <= 32'b0;
    miss_cnt <= 32'b0;
    for (i = 0; i < LINE_NUM; i = i + 1) begin
      valid_array[i] <= 1'b0;
      tag_array[i] <= {TAG_W{1'b0}};
      for (j = 0; j < WORDS_PER_LINE; j = j + 1) begin
        data_array[i][j] <= 32'b0;
      end
    end
  end else begin
    if (flush) begin
      if (ICACHE_BURST_EN) begin
        for (i = 0; i < LINE_NUM; i = i + 1) begin
          valid_array[i] <= 1'b0;
        end
      end
    end

    case (state)
      S_IDLE: begin
        if (ifu_req_valid && ifu_req_ready) begin
          access_cnt <= access_cnt + 32'd1;
          if (ICACHE_BURST_EN && hit) begin
            hit_cnt <= hit_cnt + 32'd1;
            ifu_resp_data <= data_array[req_index][req_word_off];
            state <= S_RESP;
          end else begin
            miss_cnt <= miss_cnt + 32'd1;
            if (ICACHE_BURST_EN) begin
              miss_base_addr_q <= {ifu_req_addr[31:LINE_OFF_W+2], {(LINE_OFF_W+2){1'b0}}};
              refill_beat_cnt <= {LINE_OFF_W{1'b0}};
              req_word_off_q <= req_word_off;
              req_index_q <= req_index;
              req_tag_q <= req_tag;
            end else begin
              miss_base_addr_q <= {ifu_req_addr[31:2], 2'b00};
            end
            state <= S_MISS_REQ;
          end
        end
      end

      S_MISS_REQ: begin
        if (arvalid && arready) begin
          state <= S_REFILL;
        end
      end

      S_REFILL: begin
        if (rvalid && rready && (rresp == 2'b00)) begin
          if (ICACHE_BURST_EN) begin
            data_array[req_index_q][refill_beat_cnt] <= rdata;
            if (rlast || (refill_beat_cnt == LAST_BEAT_INT[LINE_OFF_W-1:0])) begin
              tag_array[req_index_q] <= req_tag_q;
              valid_array[req_index_q] <= 1'b1;
              ifu_resp_data <= (req_word_off_q == refill_beat_cnt) ? rdata : data_array[req_index_q][req_word_off_q];
              state <= S_RESP;
            end else begin
              refill_beat_cnt <= refill_beat_cnt + 1'b1;
            end
          end else begin
            ifu_resp_data <= rdata;
            state <= S_RESP;
          end
        end
        if (rvalid && rready && (rresp != 2'b00) && (rlast || !ICACHE_BURST_EN)) begin
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

`ifdef DEBUG_ON
    if (ifu_req_valid && ifu_req_ready) begin
      $display("[ICACHE STAT] access=%0d hit=%0d miss=%0d hitrate=%0d%%",
               access_cnt + 32'd1,
               hit_cnt + ((ICACHE_BURST_EN && hit) ? 32'd1 : 32'd0),
               miss_cnt + ((ICACHE_BURST_EN && hit) ? 32'd0 : 32'd1),
               ((hit_cnt + ((ICACHE_BURST_EN && hit) ? 32'd1 : 32'd0)) * 100) / (access_cnt + 32'd1));
    end
`endif
  end
end

endmodule
