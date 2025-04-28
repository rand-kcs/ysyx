module RegisterFile #(ADDR_WIDTH = 1, DATA_WIDTH = 1) (
  input clk,
  input [DATA_WIDTH-1:0] wdata,
  input [ADDR_WIDTH-1:0] waddr,
  input wen, 
  input valid_wbu,

  input [ADDR_WIDTH-1:0] rs1,
  input [ADDR_WIDTH-1:0] rs2,
  output [DATA_WIDTH-1:0] src1,
	output [DATA_WIDTH-1:0] src2,

	output [DATA_WIDTH-1 : 0] dbg_rf [2**ADDR_WIDTH-1:0]

);
  reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
  always @(posedge clk) begin
	// solution 2 : change inside 
    if (valid_wbu && wen && waddr !== 0) rf[waddr] <= wdata;
  end

	// solution 1 ---> what's the circuit generated???
	//assign rf[0] = 32'b0;

	// solution 3, change reg0, but output from mux , price: two mux and 1 bitor
  // !!! NOT WORK WHEN difftest !!!
	//wire zeroFlag;
	//assign zeroFlag = |rs1;
	//MuxKey #(2, 1, 32) m0 (src1, zeroFlag, {
	//	1'b0 , 32'b0,
	//	1'b1 , rf[rs1]
	//});
	//MuxKey #(2, 1, 32) m1 (src2, zeroFlag, {
	//	1'b0 , 32'b0,
	//	1'b1 , rf[rs2]
	//});
  assign src1 = rf[rs1];
  assign src2 = rf[rs2];

  // For Debug:
	assign dbg_rf = rf;	
endmodule
