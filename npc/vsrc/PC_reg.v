module PC_reg (
	input clk,
	input rst,
	input [31:0] dnpc,
	output [31:0] pc
);

Reg #(32, 32'h80000000) reg_init(clk, rst, dnpc,  pc, 1'b1);

endmodule
