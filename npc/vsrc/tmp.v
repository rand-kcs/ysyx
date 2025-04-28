wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rd;
wire [31:0] imm;
wire wen;
wire valid;
wire mem_wen;

wire [31:0] src1;
wire [31:0] src2;
wire [31:0] wdata;
wire [2:0] func3;
wire [6:0] opcode;
wire [9:0] funcEU;
wire [1:0] amux1;
wire [1:0] amux2;

wire [31:0] aluout;

wire [31:0] snpc;
wire [31:0] dnpc;
wire alu2wdata;

wire [31:0] rdata;
wire [31:0] rdata_w;

wire [7:0] wmask;
wire ben; // Branch Enable
wire jen; // Jump Enable

wire [11:0] csr_addr;
wire csr_wen;
wire [31:0] csr_out;
wire [31:0] csr_wdata;
wire is_ecall;
wire is_mret;

