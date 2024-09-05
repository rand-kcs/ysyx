module hex7segPro(
	input ready,
	input clk,
	input [7:0]	 in,
	output reg [13:0] out
);

reg [13:0] mid;
bcd7seg low(in[3:0], mid[6:0]);
bcd7seg high(in[7:4], mid[13:7]);


reg [31:0] displayCouter;

always@(posedge clk) begin
	if(ready) begin
		displayCouter <= 32'h9fffff;
	end

	if(displayCouter > 32'b0)  begin
		displayCouter <= displayCouter - 1;
		out <= mid;	
	end		
	else
		out <= 14'h3fff;

end

endmodule


