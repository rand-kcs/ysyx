module EXU(
  input clk,
  input rst,

  input valid_in_idu,
  output ready_out_idu,

  output valid_out_lsu,
  input ready_in_lsu,

  // EXU 本来 要用的
  input [2:0] func3,
  input [6:0] opcode,
	input [31:0] src1,
	input [31:0] src2,
	input [31:0] imm,
	input [31:0] pc,
	input [9:0] funcEU,
	input [1:0] amux1,
	input [1:0] amux2,
  input [31:0] csr_out,

  // EXU 传递给下一单元的 : LSU, WBU
  input [7:0] wmask,
  input mem_wen,
  input mem_ren,
  
  input ben,
  input gpr_wen,
  input rd,
  input csr_wen,
  input [11:0] csr_waddr,

  output ben_buf,
  output gpr_wen_buf,
  output rd_buf,
  output csr_wen_buf,
  output [11:0] csr_waddr_buf,

  output reg func3,
  output reg mem_ren_buf,
  output reg [31:0] wdata_buf,
  output reg [7:0] wmask_buf,
  output reg mem_wen_buf,
  output reg [31:0] pc_buf,
  output reg [31:0] csr_out_buf,
  output [6:0] opcode_buf,

  output reg ben_buf,
	output reg [31:0] aluOut_buf,
  output reg [31:0] csr_wdata_buf
);

typedef enum logic [1:0] {
  IDLE      = 2'b00,
  WAIT_READY = 2'b01,
} state_t;

wire [1:0] next_state;
wire [1:0] current_state;

// state trans reg;
Reg #(2, IDLE) state(clk, rst, next_state, current_state, 1'b1);

// state change logic : next_state
always@(*) begin
  next_state = current_state;
  case (current_state)
    IDLE : begin
      if(valid_in_idu) begin
        next_state = WAIT_READY;
      end
    end
    WAIT_READY : begin
      if(ready_in_lsu) begin
        next_state = IDLE; 
      end
    end
end

// output rely on specific state;
assign ready_out_idu = current_state === IDLE;
assign valid_out_lsu = current_state === WAIT_READY;

always@(posedge clk) begin
  if (current_state === IDLE && next_state === WAIT_READY) begin  // 状态恰好转移
    ben_buf <= ben;
    aluOut_buf <= aluOut;
    csr_wdata_buf <= csr_wdata;

    // Pass 
    func3_buf <= func;
    mem_ren_buf <= mem_ren_buf;
    wdata_buf <= src2;
    wmask_buf <= wmask;
    mem_wen_buf <= mem_wen;

    ben_buf <= ben;
    gpr_wen_buf <= gpr_wen;
    rd_buf <= rd_buf;
    pc_buf <= pc;
    opcode_buf <= opcode;
    csr_out_buf <= csr_out;
    csr_wen_buf <= csr_wen;
    csr_waddr_buf <= csr_waddr;
  end
end


	/*	
		EU level : src1 and src2 refer to the rs1 rs2 GPR result;
		ALU level: asrc1 and asrc2 refer to real manipulate target, like
		pc, imm ...
	*/
	wire [31:0] asrc1;
	wire [31:0] asrc2;

	MuxKeyWithDefault # (4, 2, 32) a1MKWD (asrc1, amux1, 32'b0, {
		2'd0, 32'b0,
		2'd1, src1,
		2'd2, pc,
		2'd3, 32'b0
	});
		
	MuxKeyWithDefault # (4, 2, 32) a2MKWD (asrc2, amux2, 32'b0, {
		2'd0, 32'b0,
		2'd1, src2,
		2'd2, imm,
		2'd3, 32'b0
	});


	ALU alu(asrc1, asrc2, funcEU, aluOut);
  BranchUnit be(src1, src2, func3, opcode, ben);
  CSR_ALU csr_alu(func3,  csr_out, src1, csr_wdata);

endmodule
