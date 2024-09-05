module top(
	input [7:0] in,
	input en,
	
	output [3:0] ledr,
	output working,
	output [6:0] seg0
);

reg [7:0] inFilter;
wire [2:0] enc_out;

always@(*) begin
	if(en)
		inFilter = in;
	else
		inFilter = 8'b0;
end

encoder ec(inFilter, enc_out);
wire [3:0] ec_expand;
assign ec_expand = {1'b0, enc_out};

assign working = (|in[7:0]) & en;
assign ledr[3:0] = ec_expand;

bcd7seg dc(ec_expand, seg0);

endmodule
