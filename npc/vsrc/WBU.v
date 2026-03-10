module WBU(
  input valid_in_lsu,
  
  input [6:0]  opcode,

  input [31:0] pc,
  input [31:0] alu_out,
  input [31:0] csr_out,
  input [31:0] rdata_w,
  input gpr_wen,
  input [4:0] rd,
  input ben,

  input csr_wen,
  input [11:0] csr_waddr,
  input [31:0] csr_wdata,
  input is_ecall,
  input is_mret,

  output [31:0] dnpc,
  output [31:0] pc_buf,

  output gpr_wen_buf,
  output [4:0] rd_buf,
  output [31:0] gpr_wdata,
  output is_ecall_buf,
  output is_mret_buf,

  output csr_wen_buf,
  output [11:0] csr_waddr_buf,
  output [31:0] csr_wdata_buf,

  output valid_out_wbu
);

assign csr_waddr_buf = csr_waddr;
assign csr_wdata_buf = csr_wdata;
assign gpr_wen_buf = gpr_wen;
assign  rd_buf = rd;
assign csr_wen_buf = csr_wen;


assign valid_out_wbu = valid_in_lsu;
assign pc_buf = pc;

assign is_ecall_buf = is_ecall;
assign is_mret_buf = is_mret;

wire [31:0] snpc;
assign snpc = pc + 4;

wire jen;
wire [1:0] dnpc_select;
assign jen = (opcode === 7'b1101111 | opcode === 7'b1100111); // jal and jalr
assign dnpc_select = {is_ecall|is_mret, ben|jen};

MuxKeyWithDefault #(4, 2, 32) dnpcMKWD(dnpc, dnpc_select, 32'b0, {
	2'b00, snpc,
	2'b01, alu_out,
	2'b10, csr_out,
	2'b11, csr_out
});

MuxKeyWithDefault #(4, 7, 32) gpr_wdataMKWD(gpr_wdata, opcode, alu_out, {
	7'b1101111, snpc,     //jal 
	7'b1100111, snpc,     //jalr 
  7'b0000011, rdata_w,  // lw, lh, lb, ...
  7'b1110011, csr_out  // csr..

  // unspecify opcode lead to default -- aluout
  // ( the inst with wen)
});

endmodule

