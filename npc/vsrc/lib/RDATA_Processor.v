// 将DRAM读入的数据按照指令要求 切割或展开 Read DATA Processor  默认地址对齐
module RDATA_Processor(
  input [31:0] rdata,
  input [2:0]  func3,
  input [1:0]  low2addr,
  output reg [31:0] rdata_w
);

  reg [7:0]  byte_sel;
  reg [15:0] half_sel;

  // 1. 提取
  always @(*) begin
    // Byte extraction
    case (low2addr)
        2'b00: byte_sel = rdata[7:0];
        2'b01: byte_sel = rdata[15:8];
        2'b10: byte_sel = rdata[23:16];
        2'b11: byte_sel = rdata[31:24];
    endcase
    // Half extraction
    half_sel = (low2addr[1]) ? rdata[31:16] : rdata[15:0];
  end

  // 2. 扩展
  always @(*) begin
    case (func3)
      3'b000: rdata_w = {{24{byte_sel[7]}}, byte_sel};   // LB
      3'b001: rdata_w = {{16{half_sel[15]}}, half_sel};  // LH
      3'b010: rdata_w = rdata;                           // LW
      3'b100: rdata_w = {24'b0, byte_sel};               // LBU
      3'b101: rdata_w = {16'b0, half_sel};               // LHU
      default: rdata_w = rdata;
    endcase
  end

endmodule
