module Mem(
  input valid,
  input [31:0] raddr,
  input mem_wen,
  input [31:0] waddr,
  input [7:0] wmask,
  input [31:0] wdata,
  output [31:0] rdata
);

import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);


reg [31:0] rdata_reg;
always @(*) begin
  if (valid) begin // 有读写请求时
    rdata_reg = pmem_read(raddr);
    if (mem_wen) begin // 有写请求时
      pmem_write(waddr, wdata, wmask);
    end
  end
  else begin
    rdata_reg = 0;
  end
end

assign rdata = rdata_reg;
endmodule
