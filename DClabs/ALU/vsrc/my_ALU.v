module my_ALU(
	input [3:0] B, A,
	input [2:0] ctrl,

	output reg carry, zero, overflow,
	output reg [3:0] rst
);
// reg [3:0] {{{(A + no_B + 1'b1)B}B}B};
reg [3:0] sub_rst;

always@(*) begin
	sub_rst=4'b0;
	case (ctrl)
		3'd0 : begin
			{carry, rst} = A + B;
			zero = ~(|rst);
			overflow = (A[3] == B[3]) && (A[3] != rst[3]);
    end	
		3'd1 : begin
			{carry, rst} = A + {~B}+ 1'b1;
			zero = ~(|rst);
			overflow = (A[3] == {~B}[3]) && (A[3] != rst[3]);
		end 
		3'd2 :  begin
			carry = 1'b0;
			overflow = 1'b0;
			rst = ~A;
			zero = ~(|rst);
		end 
		3'd3 : begin
			carry = 1'b0;
			overflow = 1'b0;
			rst = A & B;
			zero = ~(|rst);
		end
		3'd4 : begin
			carry = 1'b0;
			overflow = 1'b0;
			rst = A | B;
			zero = ~(|rst);
		end
		3'd5 : begin
			carry = 1'b0;
			overflow = 1'b0;
			rst = A ^ B;
			zero = ~(|rst);
		end
		3'd6 : begin
			//no_B = ~B;
			// {mid_rst} = A + no_B + 1'b1;
			{sub_rst} = A + {~B}+ 1'b1;
			overflow = (A[3] == {~B}[3]) && (A[3] != sub_rst[3]);

			rst = {3'b0, {(A +{~B}+ 1'b1)}[3] ^ overflow};
			zero = ~rst[0];
			carry = 1'b0;
		end
		3'd7 : begin
			rst = {3'b0, ~(|(A^B))};
			zero = ~rst[0];
			carry = 1'b0;
			overflow = 1'b0;
		end
		endcase
end

endmodule;
