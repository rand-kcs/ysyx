module bcd7seg(
	input [3:0] in,
	output reg [6:0] out
);

always@(*) begin
	case (in[3:0]) 
		4'd0 : out = 7'b0000001;
		4'd1 : out = 7'b1001111;
		4'd2 : out = 7'b0010010;
		4'd3 : out = 7'b0000110;
		4'd4 : out = 7'b1001100;
		4'd5 : out = 7'b0100100;
		4'd6 : out = 7'b0100000;
		4'd7 : out = 7'b0001111;
		4'd8 : out = 7'b0000000;
		4'd9 : out = 7'b0001100;
		4'd10 : out = 7'b0001000;
		4'd11 : out = 7'b1100000;
		4'd12 : out = 7'b0110001;
		4'd13 : out = 7'b1000010;
		4'd14 : out = 7'b0110000;
		4'd15 : out = 7'b0111000;
		default : out = 7'b0;
	endcase
end

endmodule
