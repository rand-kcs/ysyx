module LSU(
  input clk,
  input rst,

  // AXI4-lite
  output reg [31:0] araddr,
  output arvalid,
  input arready,
  output [2:0] arsize,

  input [31:0] rdata,
  input [1:0] rresp,
  input rvalid,
  output rready,

  output [31:0] awaddr,
  output awvalid,
  input awready,

  output [31:0] wdata,
  output [3:0] wstrb,
  output wvalid,
  input wready,

  input [1:0] bresp,
  input bvalid,
  output bready,


  input valid_in_exu,
  output ready_out_exu,

  output valid_out_wbu,

  // 传递给 WBU
  input ben,
  input [31:0] pc,
  input [31:0] csr_out,
  input [6:0] opcode,
  
  input gpr_wen,
  input [4:0] rd,

  input csr_wen,
  input [31:0] csr_wdata,
  input [11:0] csr_waddr,
  input is_ecall,
  input is_mret,

  // LSU自己用的
  input mem_ren,
  input mem_wen,
  input [31:0] alu_out,
  input [7:0] wmask,
  input [31:0] wdata_exu,
  input [2:0] func3,

  output reg ben_buf,
  output reg [4:0] rd_buf,
  output reg [6:0] opcode_buf,

  output reg [31:0] pc_buf,
  output reg [31:0] csr_out_buf,
  output reg [31:0] alu_out_buf,
  output reg csr_wen_buf,
  output reg gpr_wen_buf,
  output reg [11:0] csr_waddr_buf,
  output reg [31:0] csr_wdata_buf,
  output is_ecall_buf,
  output is_mret_buf,

  output reg [31:0] rdata_buf,
  output reg [1:0] rresp_out,
  output reg [1:0] bresp_out
);

wire [31:0] raddr;// 同时也是 aluout
wire [31:0] waddr;
reg [31:0] addr;

assign raddr = alu_out;
assign waddr = alu_out;


// ========== 1. 状态定义与状态寄存器 ==========
// 使用独热码(one-hot)或二进制码(binary)，用parameter定义状态名
localparam [2:0] IDLE = 3'b00,
                 WAIT_ARREADY = 3'b01,
                 WAIT_RVALID = 3'b10,
                 
                 WAIT_WAWREADY= 3'b11,
                 WAIT_WREADY = 3'b100,
                 WAIT_AWREADY = 3'b101,
                 WAIT_BVALID=3'b110,

                 WAIT_WBU = 3'b111;

reg [2:0] next_state;
reg [2:0] current_state;
Reg #(3, IDLE) state(clk, rst, next_state, current_state, 1'b1);

// ========== 2. 次态逻辑（组合逻辑） ==========
always@(*) begin
  next_state = current_state;

  case (current_state)
    IDLE : begin
      if(valid_in_exu) begin
        if(mem_ren) 
          next_state = WAIT_ARREADY;
        else if(mem_wen)
          next_state = WAIT_WAWREADY;
        else 
          next_state = WAIT_WBU;
      end
    end

    WAIT_ARREADY: begin
      if(arready) 
        next_state = WAIT_RVALID;
    end

    WAIT_RVALID: begin
      if(rvalid)
        next_state = WAIT_WBU;
    end

    WAIT_WBU: begin
      next_state = IDLE;
    end

    WAIT_WAWREADY: begin
      if(awready && wready)
        next_state = WAIT_BVALID;          
      else if(awready)
        next_state = WAIT_WREADY;
      else if(wready)
        next_state = WAIT_AWREADY;
    end

    WAIT_BVALID:
      if(bvalid)
        next_state = WAIT_WBU;

    default: 
        next_state = IDLE; 
  endcase
end


// ========== 3. 输出逻辑 ==========
// 摩尔型输出（输出仅取决于当前状态）
always @(*) begin
    // 对于EXU 和 WBU 沟通
    ready_out_exu = 1'b0;
    valid_out_wbu = 1'b0;

    // 对于和DRAM 的沟通
    arvalid =1'b0;
    rready = 1'b0;
    awvalid = 1'b0;
    wvalid = 1'b0;
    bready = 1'b0;

    case (current_state)
      IDLE: begin
      // 对于EXU 和 WBU 沟通
      ready_out_exu = 1'b1;
      end

      WAIT_WBU: begin 
        valid_out_wbu = 1'b1;
      end 

      WAIT_ARREADY: begin
        arvalid = 1'b1;
      end

      WAIT_RVALID:begin
        rready = 1'b1;
      end

      WAIT_WAWREADY:begin
        awvalid = 1'b1;
        wvalid = 1'b1;
      end
      
      WAIT_BVALID: begin
        bready = 1'b1;
      end

      default: begin
        ready_out_exu = 1'b0;
        valid_out_wbu = 1'b0;

        // 对于和DRAM 的沟通
        arvalid =1'b0;
        rready = 1'b0;
        awvalid = 1'b0;
        wvalid = 1'b0;
        bready = 1'b0;
      end
    endcase
end


reg [31:0] wdata_exu_buf;

// 握手成功时的信息传递
always@(posedge clk) begin
  if (valid_in_exu && ready_out_exu) begin  // EXU -- IFU 之间的握手
    //rdata_w_buf <= rdata_w;
   
    // Direct Pass 
    ben_buf <= ben;
    opcode_buf <= opcode;
    pc_buf <= pc;
    rd_buf <= rd;
    csr_out_buf <= csr_out;
    alu_out_buf <= alu_out;
    gpr_wen_buf <=  gpr_wen;
    rd_buf <= rd;
    csr_wen_buf <= csr_wen;
    csr_waddr_buf <= csr_waddr;
    csr_wdata_buf <= csr_wdata;
    is_ecall_buf <= is_ecall;
    is_mret_buf <= is_mret;
    wdata_exu_buf <= wdata_exu;
  end
end

assign araddr = alu_out_buf;
assign awaddr = alu_out_buf;

always @(*) begin
  case (func3)
    3'b000: arsize = 3'b000 ;// LB
    3'b001: arsize = 3'b001 ;// LH
    3'b010: arsize = 3'b010 ;                        // LW
    3'b100:  arsize = 3'b000; // LBU
    3'b101:  arsize = 3'b001; // LHU
    default: arsize = 3'b010;                         // LW
  endcase
end

// rdata_w stands for treated after origin rdata from DRAM
wire [31:0] rdata_w;
RDATA_Processor rdata_processor(rdata, func3, alu_out_buf[1:0], araddr, rdata_w);

WDATA_Processor wdata_processor(.wdata_origin(wdata_exu_buf), .func3(func3), .addr_offset(alu_out_buf[1:0]), .wdata(wdata), .wstrb(wstrb));

always @(posedge clk) begin
  if(rvalid && rready) begin
    rdata_buf <= rdata_w;
    rresp_out <= rresp;
  end

  if(bready && bvalid)
    bresp_out <= bresp;
end


endmodule
