module mux41_2(
	input [1:0]	X0,
	input [1:0]	X1,
	input [1:0]	X2,
	input [1:0]	X3,
	input [1:0] s,
	output [1:0] y
);



MuxKey #(4, 2, 2) m0 (y, s, {
	2'd0, X0,
	2'd1, X1,
	2'd2, X2,
	2'd3, X3
});

endmodule
