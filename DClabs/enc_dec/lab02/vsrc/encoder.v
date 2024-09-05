module encoder(
	input [7:0] in,
	output reg [2:0] out
);

always@(*) begin 
	casez (in[7:0])
		8'b1zzzzzzz : out = 3'd7;
		8'b01zzzzzz : out = 3'd6;
		8'b001zzzzz : out = 3'd5;
		8'b0001zzzz : out = 3'd4;
		8'b00001zzz : out = 3'd3;
		8'b000001zz : out = 3'd2;
		8'b0000001z : out = 3'd1;
		8'b00000001 : out = 3'd0;
		default : out = 3'd0;
	endcase
end



endmodule
