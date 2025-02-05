module ALU(
	input [31:0] asrc1,
	input [31:0] asrc2,
	input [2:0] func,
	output [31:0] out
);


MuxKeyWithDefault #(1, 3, 32) aluMux (out, func, 32'b0, {
	3'b0, asrc1 + asrc2
});

endmodule
