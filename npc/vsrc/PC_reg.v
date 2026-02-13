module PC_reg (
	input clk,
	input rst,
  input valid_wbu,
	input [31:0] dnpc,
	output [31:0] pc,
  output reg done
);

Reg #(32, 32'h30000000) reg_init(clk, rst, dnpc, pc, valid_wbu);

always@(posedge clk) begin
  if(rst)
    done <= 1'b1;
  else if(valid_wbu)
    done <= 1'b1;
  else
    done <= 1'b0;
end

endmodule
