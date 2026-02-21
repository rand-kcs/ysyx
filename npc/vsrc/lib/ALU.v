module ALU(
	input [31:0] asrc1,
	input [31:0] asrc2,
	input [9:0] funcEU,
	output [31:0] out
);

wire sign_cmp;
wire unsign_cmp;

wire [31:0] add_b;
wire cin;
wire [32:0] result;

MuxKeyWithDefault #(3, 10, 32) add_bMux (add_b, funcEU, asrc2, {
  {3'h0, 7'h20} , ~asrc2 , // Minus
  {3'h2, 7'h00} , ~asrc2 , // SetLessThan
  {3'h3, 7'h00} , ~asrc2   // SetLessThanImm
});

MuxKeyWithDefault #(3, 10, 1) cin_Mux (cin, funcEU, 1'b0, {
  {3'h0, 7'h20} , 1'b1, // Minus
  {3'h2, 7'h00} , 1'b1, // SetLessThan
  {3'h3, 7'h00} , 1'b1  // SetLessThanImm
});

assign result = asrc1 + add_b + {31'b0, cin};

assign sign_cmp =  (asrc1[31] === asrc2[31] & result[31] === 1'b1) | (asrc1[31] === 1'b1 & asrc2[31]===1'b0);

// todo-> fix: The Carry Bit should include the ~+ period; otherwise 1 < 0 would be
// true
assign unsign_cmp =  ~result[32];


MuxKeyWithDefault #(10, 10, 32) aluMux (out, funcEU, 32'b0, {
	{3'h0, 7'h00}, result[31:0],
	{3'h0, 7'h20}, result[31:0],
	{3'h4, 7'h00}, asrc1 ^ asrc2,
	{3'h6, 7'h00}, asrc1 | asrc2,
	{3'h7, 7'h00}, asrc1 & asrc2,
	{3'h1, 7'h00}, asrc1 << asrc2[4:0],
	{3'h5, 7'h00}, asrc1 >> asrc2[4:0],
	{3'h5, 7'h20}, $signed(asrc1) >>> asrc2[4:0],     // sign extend

	{3'h2, 7'h00}, {31'b0, sign_cmp  }, // Signed Cmp
	{3'h3, 7'h00}, {31'b0, unsign_cmp} //Unsigned Cmp
});

endmodule
