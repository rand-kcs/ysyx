module top(
	input clk,rst,ps2_clk,ps2_data,
	output [6:0] seg0, seg1,
	output [6:0] seg2, seg3,
	output [6:0] seg4, seg5,
	output reg[7:0] count,
	output ready,
	output shiftLD,
	output ctrlLD
);

/*
initial begin
$dumpfile("wave.fst");
$dumpvars();
end
*/

reg [7:0] data;
reg [7:0] data_prev;
wire nextdata_n,overflow;
//reg [7:0] count;

assign ctrlLD = 1'b1;

ps2_keyboard mykeyboard(clk, ~rst, ps2_clk,ps2_data, data, data_prev, ready);


always@(posedge clk) begin
	if(rst) begin
		 count <= 0;
	end
	else if(ready && data == 8'h12) begin
		shiftLD <= 1;
		if(data_prev == 8'hf0) begin
		$display("in loop: ready!data: %x data_prev: %x", data, data_prev);
			shiftLD <= 0;
		end
	end
	else if(ready && data == 8'hf0) begin
		count <= count + 1'b1;
	end
	else 
		count <= count;
end

bcd7seg cntlow(count[3:0], seg4);
bcd7seg cnthigh(count[7:4], seg5);


hex7segPro segout1(ready, clk, data,{seg1,seg0});

reg [7:0] ascii;
transAscii trans(data, ascii);

hex7segPro segout2(ready, clk, ascii,{seg3,seg2});


endmodule
