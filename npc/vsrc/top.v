module top(
		input clk,
		input rst,
		input [31:0] inst,
		output [31:0] inst_dbg,
		output [31:0] pc,
		output [31:0] rf_dbg [31:0],
		output [31:0] src2_solveWaring,
		output [2:0]  func3_solveWarn
);

assign inst_dbg = inst;
assign src2_solveWaring = src2;
assign func3_solveWarn = func3;

wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rd;
wire [31:0] imm;
wire wen;

wire [31:0] src1;
wire [31:0] src2;
wire [31:0] wdata;
wire [2:0] func3;


PC_reg pc_reg(clk, rst, pc);

// Decode Unit  -- RF -- EX   connected

IDU idu (inst, rs1, rs2, rd, imm, wen, func3);

RegisterFile #(5, 32) RF(clk, wdata, rd, wen, rs1, rs2, src1, src2, rf_dbg);

ExecuteUnit eu(src1, imm, wdata);

initial begin
	$display("[%0t] Tracing to logs/vlt_dump.fst", $time);
	$dumpfile("logs/vlt_dump.fst");
	$dumpvars();
	#50 $finish;
end 

export "DPI-C" function ebreakYes;

function ebreakYes;
	ebreakYes =  !|((inst & 32'hfff0707f) ^ 32'h00100073);
endfunction


endmodule
