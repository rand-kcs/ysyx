module CSR_ALU(
  input [2:0] func3,
  input [31:0] csr_data,
  input [31:0] src1,

  output [31:0] csr_wdata
);

MuxKeyWithDefault #(2, 3, 32) wdata_MKWD(csr_wdata, func3, 32'b0,{
  3'b001, src1,
  3'b010, csr_data | src1
 });


endmodule
