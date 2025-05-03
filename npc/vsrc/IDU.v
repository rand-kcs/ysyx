module IDU (
  input clk,
  input rst,

  input valid_in_ifu,
  output ready_out_ifu,

  output valid_out_exu,
  input ready_in_exu,

  input [31:0] pc,
	input [31:0] inst,
  output reg [31:0] pc_buf,
	output reg [4:0] rs1_buf,
	output reg [4:0] rs2_buf,
	output reg [4:0] rd_buf,
	output reg [31:0] imm_buf,
	output reg gpr_wen_buf,
	output reg [2:0] func3_buf,
	output reg [9:0] funcEU_buf,
	output reg [1:0] amux1_buf,
	output reg [1:0] amux2_buf,
	output reg [6:0] opcode_buf,
  output reg mem_ren_buf,
  output reg mem_wen_buf,
  output reg [7:0] wmask_buf,

  output reg [11:0] csr_addr_buf,
  output reg csr_wen_buf,
  output reg is_ecall_buf,
  output reg is_mret_buf
);

wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rd;
wire [31:0] imm;
wire gpr_wen;
wire [2:0] func3;
wire [9:0] funcEU;
wire [1:0] amux1;
wire [1:0] amux2;
wire [6:0] opcode;
wire mem_ren;
wire mem_wen;
wire [7:0] wmask;

wire [11:0] csr_addr;
wire csr_wen;
wire is_ecall;
wire is_mret;




parameter IDLE       = 2'b00;
parameter WAIT_READY = 2'b01;


reg [1:0] next_state;
reg [1:0] current_state;

// state trans reg;
Reg #(2, IDLE) state(clk, rst, next_state, current_state, 1'b1);

// state change logic : next_state
always@(*) begin
  next_state = current_state;
  case (current_state)
    IDLE : begin
      if(valid_in_ifu) begin
        next_state = WAIT_READY;
      end
    end
    WAIT_READY : begin
      if(ready_in_exu) begin
        next_state = IDLE; 
      end
    end
    default: 
        next_state = IDLE; 
  endcase
end

// output rely on specific state;
assign ready_out_ifu = current_state === IDLE;
assign valid_out_exu = current_state === WAIT_READY;

always@(posedge clk) begin
  if (current_state === IDLE && next_state === WAIT_READY) begin  // 状态恰好转移
    pc_buf <= pc;
    rs1_buf <= rs1;
    rs2_buf <= rs2;
    rd_buf <= rd;
    imm_buf <= imm;
    gpr_wen_buf <= gpr_wen;
    func3_buf <= func3;         
    funcEU_buf <= funcEU;       
    amux1_buf <= amux1;         
    amux2_buf <= amux2;         
    opcode_buf <= opcode;       
    mem_ren_buf <= mem_ren;         
    mem_wen_buf <= mem_wen;     
    wmask_buf <= wmask;         
    csr_addr_buf <= csr_addr;    
    csr_wen_buf <= csr_wen;     
    is_ecall_buf <= is_ecall;    
    is_mret_buf <= is_mret;     
  end
end


assign func3 = inst[14:12];

wire [6:0] func7;
MuxKeyWithDefault # (6, 10, 7) func7_MKWD (func7,{opcode, func3}, inst[31:25], {
 {7'b0010011, 3'h0},  7'b0,
 {7'b0010011, 3'h4},  7'b0,
 {7'b0010011, 3'h6},  7'b0,
 {7'b0010011, 3'h7},  7'b0,
 {7'b0010011, 3'h2},  7'b0,
 {7'b0010011, 3'h3},  7'b0
 });

assign rs1 = inst[19:15];
assign rs2 = inst[24:20];
assign rd = inst[11:7];

assign opcode = inst[6:0];

wire [2:0] itype;
TypeIndicator typeIc (opcode, itype);

// modulize a equaler ? 
assign gpr_wen =  itype === `I_TYPE | itype === `U_TYPE | itype === `J_TYPE | itype ===`R_TYPE;
assign mem_ren = opcode === 7'b0000011 ; // load 
assign mem_wen = opcode === 7'b0100011 ;

assign csr_addr = inst[31:20];
assign csr_wen = opcode === 7'b1110011 ;
assign is_ecall = inst === 32'h00000073;
assign is_mret = inst === 32'h30200073 ;


// Make Immgen
ImmGenerator immG(itype, inst, imm);

// itype => funcEU X!   opcode => funcEU ( func3 or add )
MuxKeyWithDefault # (2, 7, 10) funcEU_MKWD(funcEU, opcode, 10'b0, {
	7'b0110011, {func3, func7}, // add, sub, ...
	7'b0010011, {func3, func7} // addi, subi, ... the func7 has already updated.
  // default funcEU would be Add.
});

/*
* As for amux1
  2'd0 ->  0
  2'd1 ->  rs1
  2'd2 ->  pc
  2'd3 ->  0
*/
MuxKeyWithDefault # (9, 7, 2) amux1_MKWD(amux1, opcode, 2'b0, {
	7'b0110111, 2'd0, // lui asrc1 select 0 --U_type

	7'b0010011, 2'd1, // Normal addi, subi, xori.., select src1 I-type
	7'b1100111, 2'd1, // jalr, select reg src1  --I-type
  7'b0000011, 2'd1, // lw, lh, lb...
  7'b0100011, 2'd1, // sw, sb, sh
  7'b0110011, 2'd1, // add, sub, ...

	7'b0010111, 2'd2, // auipc  select pc --U_Type
	7'b1101111, 2'd2, // jal  select pc   --J_Type
	7'b1100011, 2'd2 //  branch, select pc
});

/*
* As for amux2
  2'd0 ->  0
  2'd1 ->  rs2
  2'd2 ->  imm
  2'd3 ->  0
*/

MuxKeyWithDefault # (9, 7, 2) amux2_MKWD(amux2, opcode, 2'b0, {
  7'b0110011, 2'd1, // add, sub, ...
	7'b0110111, 2'd2, // lui asrc2 select imm
	7'b0010011, 2'd2, // Normal addi, subi, xori.., select imm
  7'b1101111, 2'd2, // jal, select imm
	7'b1100111, 2'd2, // jalr , select imm
	7'b0010111, 2'd2,  // auipc  select imm
  7'b0000011, 2'd2,  // lw, lh, ...
  7'b0100011, 2'd2,  // sw, sh, sb
  7'b1100011, 2'd2   // branch
});

MuxKeyWithDefault # (3, 3, 8) wmask_MKWD(wmask, func3, 8'b0, {
  3'h0, 8'h1,
  3'h1, 8'h3,
  3'h2, 8'hf
});

endmodule
