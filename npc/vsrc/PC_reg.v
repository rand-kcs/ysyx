module PC_reg (
	input clk,
	input rst,
	output [31:0] pc
);

wire [31:0] snpc;

assign snpc = pc + 4;
Reg #(32, 32'h80000000) reg_init(clk, rst, snpc,  pc, 1'b1);

endmodule
