module RDATA_Processor(
  input [31:0] rdata,
  input [2:0] func3,
  output [31:0] rdata_w
);

MuxKeyWithDefault # (5, 3, 32) rdataMKWD (rdata_w, func3, rdata, {
  3'h0, {{24{rdata[7]}}, rdata[7:0]},     // lb
  3'h1, {{16{rdata[15]}}, rdata[15:0]},   // lh
  3'h2, rdata,
  3'h4, {{24{1'b0}}, rdata[7:0]},         //lbu
  3'h5, {{16{1'b0}}, rdata[15:0]}         //lhu
});


endmodule
