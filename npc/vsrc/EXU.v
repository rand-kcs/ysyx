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

  // BPU update (fire once when EXU accepts a CFI)
  output wire        bpu_update_en,
  output wire [31:0] bpu_update_pc,
  output wire        bpu_update_taken,
  output wire [31:0] bpu_update_target,

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

  // predicted next pc from front-end (aligned with this instruction)
  input [31:0] pred_next_pc,

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
  output reg [31:0] csr_wdata_buf

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
// - 使用 BPU 动态预测：仅当预测失败（或特权跳转）时 redirect
// - 只在本级接收该条指令时置位一次，避免 LSU 阻塞导致重复 flush
// ------------------------------------------------------------
reg redirect_valid_r;
reg [31:0] redirect_pc_r;
assign redirect_valid = redirect_valid_r;
assign redirect_pc    = redirect_pc_r;

wire [31:0] snpc = pc + 32'd4;
wire is_branch = (opcode == 7'b1100011);
wire is_jal    = (opcode == 7'b1101111);
wire is_jalr   = (opcode == 7'b1100111);
wire is_cfi    = is_branch | is_jal | is_jalr;

wire actual_taken  = is_branch ? ben : (is_jal | is_jalr);
wire [31:0] actual_target_taken = aluOut;      // branch/jal/jalr target are all from ALU
wire [31:0] cfi_dnpc_real = actual_taken ? actual_target_taken : snpc;  // real next pc for branch/jump
wire mispredict = is_cfi && (pred_next_pc != cfi_dnpc_real);

wire redirect_fire = valid_in_idu && ex_can_accept && (mispredict | is_ecall | is_mret);
wire [31:0] redirect_pc_next = (is_ecall | is_mret) ? csr_out : cfi_dnpc_real;

`ifdef DEBUG_ON
// ------------------------------------------------------------
// Performance counters (DEBUG only)
// - Count CFI (branch/jal/jalr) prediction correctness in EXU
// ------------------------------------------------------------
reg [31:0] cfi_total_cnt;
reg [31:0] cfi_correct_cnt;
reg [31:0] cfi_misp_cnt;
wire cfi_fire = valid_in_idu && ex_can_accept && is_cfi;
`endif

assign bpu_update_en     = valid_in_idu && ex_can_accept && is_cfi;
assign bpu_update_pc     = pc;
assign bpu_update_taken  = actual_taken;
assign bpu_update_target = actual_target_taken;

always @(posedge clk) begin

`ifdef DEBUG_ON_DETAIL
    $display("EXU Current State: ex_valid: ", ex_valid);
`endif

  if (rst) begin
    ex_valid <= 1'b0;
    redirect_valid_r <= 1'b0;
    redirect_pc_r    <= 32'b0;

`ifdef DEBUG_ON
    cfi_total_cnt   <= 32'd0;
    cfi_correct_cnt <= 32'd0;
    cfi_misp_cnt    <= 32'd0;
`endif
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

`ifdef DEBUG_ON
    if (cfi_fire) begin
      cfi_total_cnt <= cfi_total_cnt + 32'd1;
      if (mispredict) begin
        cfi_misp_cnt <= cfi_misp_cnt + 32'd1;
      end
      else begin
        cfi_correct_cnt <= cfi_correct_cnt + 32'd1;
      end

      $display("[BPU PERF] pc=0x%08x pred_next=0x%08x real_next=0x%08x %s | total=%0d correct=%0d misp=%0d",
               pc, pred_next_pc, cfi_dnpc_real, mispredict ? "MISPRED" : "CORRECT",
               cfi_total_cnt + 32'd1,
               mispredict ? cfi_correct_cnt : (cfi_correct_cnt + 32'd1),
               mispredict ? (cfi_misp_cnt + 32'd1) : cfi_misp_cnt);
    end
`endif

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
