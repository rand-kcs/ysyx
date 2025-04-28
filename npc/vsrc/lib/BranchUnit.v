module BranchUnit(
	input [31:0] asrc1,
	input [31:0] asrc2,
	input [2:0] func3,
	input [6:0] opcode,
	output ben
);

wire eq;
wire ne;
wire lt;
wire gt;
wire ltu;
wire gtu;

wire cin;
wire [32:0] result;
wire [31:0] n_asrc2 = ~asrc2;

assign cin = 1'b1;
assign result = asrc1 + n_asrc2 + {31'b0, cin};

assign lt =  (asrc1[31] === asrc2[31] & result[31] === 1'b1) | (asrc1[31] === 1'b1 & asrc2[31]===1'b0);

// todo-> fix: The Carry Bit should include the ~+ period; otherwise 1 < 0 would be
// true
assign ltu =  ~result[32];

assign gt = ~lt;
assign gtu = ~ltu;

assign ne = (|result[31:0]);
assign eq = ~ne;

wire isBranchInst = opcode ===7'b1100011;

MuxKeyWithDefault #(6, 3, 1) benMKWD(ben, func3, 1'b0, {
  3'h0, eq & isBranchInst,
  3'h1, ne & isBranchInst,
  3'h4, lt & isBranchInst,
  3'h5, (gt | eq) & isBranchInst,
  3'h6, ltu & isBranchInst,
  3'h7, (gtu | eq) & isBranchInst
});

endmodule
