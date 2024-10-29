module top(
	input load, rst, clk,

	output [6:0] seg0,
	output [6:0] seg1
);

reg [7:0] Q;
reg [7:0] data = 8'b1;

shiftReg sr(load, rst, clk, data, Q);

bcd7seg trans1(Q[3:0], seg0);
bcd7seg trans2(Q[7:4], seg1);

endmodule

