module top(
	input [3:0]	B,A,
	input [2:0] ctrl,

	output carry,zero,overflow,
	output [3:0] rst,
	output [6:0] seg0
);

my_ALU alu(B,A,ctrl, carry, zero, overflow, rst);
bcd7seg my_seg(rst, seg0);

endmodule
