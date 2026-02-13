module RDATA_Processor(
  input [31:0] rdata,
  input [2:0]  func3,
  input [1:0]  low2addr,
  input [31:0] araddr,
  output reg [31:0] rdata_w
);

  reg [7:0]  byte_sel;
  reg [15:0] half_sel;

import "DPI-C" function void difftest_skip_ref();
  
  // 定义地址区间判断逻辑
  // 1. 区间 0x2000_0000 ~ 0x2000_0FFF MROM 
  wire is_region_2000 = (araddr >= 32'h2000_0000 && araddr <= 32'h2000_0fff);
  
  // 2. 区间 0x1000_0000 ~ 0x1000_0006 UART
  wire is_region_1000 = (araddr >= 32'h1000_0000 && araddr <= 32'h1000_0006);

  // 2. 区间 0x3000_0000 ~ 0x3fff_ffff FLASH
  wire is_region_3000 = (araddr >= 32'h3000_0000 && araddr <= 32'h3fff_ffff);

  // 汇总：是否处于“不移位”模式
  // 如果在这两个特殊区间内，我们将忽略 low2addr，直接取最低位
  wire no_shift_en = is_region_2000 | is_region_1000 | is_region_3000;

  // 1. 提取 (Extraction)
  always @(*) begin
    // Byte extraction
    if (no_shift_en) begin
        // 特殊模式：不进行移位，总是取最低字节
        byte_sel = rdata[7:0];
    end else begin
        // 标准模式 (0x0f00... 等其他区间)：根据地址低两位选择字节
        case (low2addr)
            2'b00: byte_sel = rdata[7:0];
            2'b01: byte_sel = rdata[15:8];
            2'b10: byte_sel = rdata[23:16];
            2'b11: byte_sel = rdata[31:24];
        endcase
    end

    // Half extraction
    if (no_shift_en) begin
        // 特殊模式：不进行移位，总是取最低半字
        half_sel = rdata[15:0];
    end else begin
        // 标准模式：根据地址第1位选择半字
        half_sel = (low2addr[1]) ? rdata[31:16] : rdata[15:0];
    end
  end

  // 2. 扩展 (Extension)
  // 这部分逻辑保持不变，因为我们已经在上面处理了数据的选取
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

  always@(*) begin
    if(is_region_1000)
      difftest_skip_ref();
  end

endmodule
