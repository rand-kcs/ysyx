module EXU(
  input clk,
  input rst,

  input valid_in_idu,
  output ready_out_idu,

  output valid_out_lsu,
  input ready_in_lsu,

  // EXU/LSU 级提前产生的 redirect 信息（用于静态预测 pc+4 的纠正）
  output wire redirect_valid,
  output wire [31:0] redirect_pc,

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
  
  input gpr_wen,
  input [4:0] rd,
  input csr_wen,
  input [11:0] csr_waddr,


  input is_ecall,
  input is_mret,

  output reg gpr_wen_buf,
  output reg [4:0] rd_buf,
  output reg is_ecall_buf,
  output reg is_mret_buf,
  output reg csr_wen_buf,
  output reg [11:0] csr_waddr_buf,

  output reg [2:0] func3_buf,
  output reg mem_ren_buf,
  output reg [31:0] wdata_buf,
  output reg [7:0] wmask_buf,
  output reg mem_wen_buf,
  output reg [31:0] pc_buf,
  output reg [31:0] csr_out_buf,
  output reg [6:0] opcode_buf,

  output reg ben_buf,
	output reg [31:0] aluOut_buf,
  output reg [31:0] csr_wdata_buf,

);

wire [31:0] aluOut;
wire [31:0] csr_wdata;

// ID/EX 流水寄存器 valid 标志
reg ex_valid;

// 当本级为空或 LSU 在本拍准备好接收时，才允许 IDU 送入新指令
wire ex_can_accept = ~ex_valid || ready_in_lsu;

assign ready_out_idu = ex_can_accept;
assign valid_out_lsu = ex_valid;

// ------------------------------------------------------------
// redirect：EXU 级发出“单拍脉冲”的 flush/redirect
// - 静态预测 pc+4，因此仅当 ben/jal/jalr/ecall/mret 时需要 redirect
// - 只在本级接收该条指令时置位一次，避免 LSU 阻塞导致重复 flush
// ------------------------------------------------------------
reg redirect_valid_r;
reg [31:0] redirect_pc_r;
assign redirect_valid = redirect_valid_r;
assign redirect_pc    = redirect_pc_r;

wire [31:0] snpc = pc + 32'd4;
wire jen = (opcode == 7'b1101111) | (opcode == 7'b1100111); // jal / jalr
wire redirect_fire = valid_in_idu && ex_can_accept && (ben | jen | is_ecall | is_mret);
wire [1:0] dnpc_select = {is_ecall | is_mret, ben | jen};
wire [31:0] redirect_pc_next;
MuxKeyWithDefault #(4, 2, 32) exu_redirect_pc_mux(redirect_pc_next, dnpc_select, 32'b0, {
  2'b00, snpc,
  2'b01, aluOut,
  2'b10, csr_out,
  2'b11, csr_out
});

always @(posedge clk) begin

`ifdef DEBUG_ON_DETAIL
    $display("EXU Current State: ex_valid: ", ex_valid);
`endif

  if (rst) begin
    ex_valid <= 1'b0;
    redirect_valid_r <= 1'b0;
    redirect_pc_r    <= 32'b0;
  end
  else if (ex_can_accept) begin
    ex_valid <= valid_in_idu;

    // 默认清零，若本拍接收的指令需要 redirect，则产生单拍脉冲
    redirect_valid_r <= 1'b0;
    if (redirect_fire) begin
      redirect_valid_r <= 1'b1;
      redirect_pc_r    <= redirect_pc_next;
    end
    else begin
      redirect_pc_r    <= redirect_pc_r;
    end

    if (valid_in_idu) begin
      ben_buf        <= ben;
      aluOut_buf     <= aluOut;
      csr_wdata_buf  <= csr_wdata;

      // 传递控制和数据信号到 LSU/WBU
      func3_buf      <= func3;
      mem_ren_buf    <= mem_ren;
      wdata_buf      <= src2;
      wmask_buf      <= wmask;
      mem_wen_buf    <= mem_wen;
      is_ecall_buf   <= is_ecall;
      is_mret_buf    <= is_mret;

      gpr_wen_buf    <= gpr_wen;
      rd_buf         <= rd;
      pc_buf         <= pc;
      opcode_buf     <= opcode;
      csr_out_buf    <= csr_out;
      csr_wen_buf    <= csr_wen;
      csr_waddr_buf  <= csr_waddr;
    end 
  end
  else begin
    // LSU 不 ready 且本级有指令：保持 redirect 输出为 0，避免重复 flush
    redirect_valid_r <= 1'b0;
    redirect_pc_r    <= redirect_pc_r;
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

  wire ben;
  BranchUnit be(src1, src2, func3, opcode, ben);

  CSR_ALU csr_alu(func3,  csr_out, src1, csr_wdata);

endmodule
