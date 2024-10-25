module shiftReg(
	input load,rst,clk,
	input [7:0] data,
	output reg [7:0] Q
);

always@(posedge clk) begin
	if(rst) 
		Q <= 8'b0;
	else if (load)
		Q <= data;
	else
		Q <= {Q[4]^Q[3]^Q[2]^Q[0],Q[7:1]};
end


endmodule
