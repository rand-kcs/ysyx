module ARBITER (
  input clk,
  input rst,
  
  // 主设备0接口
  input [31:0] m0_araddr,
  input        m0_arvalid,
  input [2:0]   m0_arsize,
  output reg   m0_arready,      // 改为reg
  
  output reg [31:0] m0_rdata,   // 改为reg
  output reg [1:0]  m0_rresp,   // 改为reg
  output reg        m0_rvalid,  // 改为reg
  input             m0_rready,
  
  input [31:0]  m0_awaddr,
  input         m0_awvalid,
  output reg    m0_awready,     // 改为reg
  
  input [31:0]  m0_wdata,
  input [3:0]   m0_wstrb,
  input         m0_wvalid,
  output reg    m0_wready,      // 改为reg
  
  output reg [1:0] m0_bresp,    // 改为reg
  output reg       m0_bvalid,   // 改为reg
  input            m0_bready,
  
  // 主设备1接口
  input [31:0]  m1_araddr,
  input         m1_arvalid,
  input [2:0]   m1_arsize,
  output reg    m1_arready,     // 改为reg
  
  output reg [31:0] m1_rdata,   // 改为reg
  output reg [1:0]  m1_rresp,   // 改为reg
  output reg        m1_rvalid,  // 改为reg
  input             m1_rready,
  
  input [31:0]  m1_awaddr,
  input         m1_awvalid,
  output reg    m1_awready,     // 改为reg
  
  input [31:0]  m1_wdata,
  input [3:0]   m1_wstrb,
  input         m1_wvalid,
  output reg    m1_wready,      // 改为reg
  
  output reg [1:0] m1_bresp,    // 改为reg
  output reg       m1_bvalid,   // 改为reg
  input            m1_bready,
  
  // 从设备接口
  output reg [31:0] s_araddr,   // 改为reg
  output reg        s_arvalid,  // 改为reg
  output reg [2:0]  s_arsize,
  input             s_arready,
  
  input [31:0]  s_rdata,
  input [1:0]   s_rresp,
  input         s_rvalid,
  output reg    s_rready,       // 改为reg
  
  output reg [31:0] s_awaddr,   // 改为reg
  output reg        s_awvalid,  // 改为reg
  input             s_awready,
  
  output reg [31:0] s_wdata,    // 改为reg
  output reg [3:0]  s_wstrb,    // 改为reg
  output reg        s_wvalid,   // 改为reg
  input             s_wready,
  
  input [1:0]   s_bresp,
  input         s_bvalid,
  output reg    s_bready        // 改为reg
);
// ========== 1. 状态定义与状态寄存器 ==========
// 读事务状态机
localparam S_IDLE_R = 3'd0,
//           S_WAIT_ARREADY_M0 = 3'd1,
           S_WAIT_RVALID_M0 = 3'd2,
 //          S_WAIT_ARREADY_M1 = 3'd3,
           S_WAIT_RVALID_M1 = 3'd4;

// 写事务状态机
localparam S_IDLE_W = 3'd0,
           S_WAIT_WREADY_M0 = 3'd1,
           S_WAIT_BVALID_M0 = 3'd2,
           S_WAIT_WREADY_M1 = 3'd3,
           S_WAIT_BVALID_M1 = 3'd4;

reg [2:0] current_state_r, next_state_r; // 读状态寄存器
reg [2:0] current_state_w, next_state_w; // 写状态寄存器

// ========== 时序逻辑部分：只在时钟沿更新状态 ==========
always @(posedge clk) begin
    if (rst) begin
        current_state_r <= S_IDLE_R; // 明确的复位状态
        current_state_w <= S_IDLE_W; // 明确的复位状态
    end else begin
        current_state_r <= next_state_r; // 状态转移
        current_state_w <= next_state_w; // 状态转移
    end
end

// ========== 2. 次态逻辑（组合逻辑） ==========
// 读状态机的次态逻辑
always @(*) begin
    // 默认值：防止生成锁存器
    next_state_r = current_state_r;
    
    case (current_state_r)
        S_IDLE_R: begin
            if (m0_arvalid && s_arready) begin
                next_state_r = S_WAIT_RVALID_M0;
            end
            else if (m1_arvalid && s_arready) begin
                next_state_r = S_WAIT_RVALID_M1;
            end
        end
        
        S_WAIT_RVALID_M0: begin
            if (m0_rready && s_rvalid) begin
                next_state_r = S_IDLE_R;
            end
        end

        S_WAIT_RVALID_M1: begin
            if (m1_rready && s_rvalid) begin
                next_state_r = S_IDLE_R;
            end
        end

        default: begin
            next_state_r = S_IDLE_R; // 异常时恢复到安全状态
        end
    endcase
end

// 写状态机的次态逻辑
always @(*) begin
    // 默认值：防止生成锁存器
    next_state_w = current_state_w;
    
    case (current_state_w)
        S_IDLE_W: begin
            if (m0_awvalid && s_awready && m0_wvalid && s_wready) begin
                next_state_w = S_WAIT_BVALID_M0;
            end
            else if (m0_awvalid && s_awready) begin
                next_state_w = S_WAIT_WREADY_M0;
            end
            else if (m1_awvalid && s_awready && m1_wvalid && s_wready) begin
                next_state_w = S_WAIT_BVALID_M1;
            end
            else if (m1_awvalid && s_awready) begin
                next_state_w = S_WAIT_WREADY_M1;
            end
        end

        S_WAIT_WREADY_M0: begin
            if (m0_wvalid && s_wready) begin
                next_state_w = S_WAIT_BVALID_M0;
            end
        end

        S_WAIT_WREADY_M1: begin
            if (m1_wvalid && s_wready) begin
                next_state_w = S_WAIT_BVALID_M1;
            end
        end
      
        S_WAIT_BVALID_M0: begin
            if (m0_bready && s_bvalid) begin
                next_state_w = S_IDLE_W;
            end
        end

        S_WAIT_BVALID_M1: begin
            if (m1_bready && s_bvalid) begin
                next_state_w = S_IDLE_W;
            end
        end

        default: begin
            next_state_w = S_IDLE_W; // 异常时恢复到安全状态
        end
    endcase
end

// ========== 3. 输出逻辑 ==========
// 读事务输出逻辑
always @(*) begin
    // 默认值：所有信号赋值为0
    m0_arready = 1'b0;
    m0_rdata = 32'b0;
    m0_rresp = 2'b00;
    m0_rvalid = 1'b0;
    
    m1_arready = 1'b0;
    m1_rdata = 32'b0;
    m1_rresp = 2'b00;
    m1_rvalid = 1'b0;
    
    s_araddr = 32'b0;
    s_arsize = 3'b010;
    s_arvalid = 1'b0;
    s_rready = 1'b0;
    
    case (current_state_r)
        S_IDLE_R: begin
            // TO SLAVE
            s_arvalid = m0_arvalid | m1_arvalid; 
            if (m0_arvalid === 1'b1) begin
                s_araddr = m0_araddr;
                s_arsize = m0_arsize;
            end 
            else begin
                s_araddr = m1_araddr;
                s_arsize = m1_arsize;
            end
            // TO MASTER
            m0_arready = s_arready; 
            m1_arready = s_arready & (!m0_arvalid);
        end

        S_WAIT_RVALID_M0: begin
            m0_rdata = s_rdata;
            m0_rresp = s_rresp;
            m0_rvalid = s_rvalid;
            s_rready = m0_rready;
        end

        S_WAIT_RVALID_M1: begin
            m1_rdata = s_rdata;
            m1_rresp = s_rresp;
            m1_rvalid = s_rvalid;
            s_rready = m1_rready;
        end

        default: begin
            // 在默认分支中，所有信号已经赋值为0
        end
    endcase
end

// 写事务输出逻辑
always @(*) begin
    // 默认值：所有信号赋值为0
    m0_awready = 1'b0;
    m0_wready = 1'b0;
    m0_bresp = 2'b00;
    m0_bvalid = 1'b0;
    
    m1_awready = 1'b0;
    m1_wready = 1'b0;
    m1_bresp = 2'b00;
    m1_bvalid = 1'b0;
    
    s_awaddr = 32'b0;
    s_awvalid = 1'b0;
    s_wdata = 32'b0;
    s_wstrb = 4'b0;
    s_wvalid = 1'b0;
    s_bready = 1'b0;
    
    case (current_state_w)
        S_IDLE_W: begin
            // TO SLAVE
            s_awvalid = m0_awvalid | m1_awvalid;
            if (m0_awvalid === 1'b1) begin
                s_awaddr = m0_awaddr;
                s_awvalid = m0_awvalid;
                s_wdata = m0_wdata;
                s_wstrb = m0_wstrb;
                s_wvalid = m0_wvalid;
            end
            else begin
                s_awaddr = m1_awaddr;
                s_awvalid = m1_awvalid;
                s_wdata = m1_wdata;
                s_wstrb = m1_wstrb;
                s_wvalid = m1_wvalid;
            end
            // TO MASTER
            m0_awready = s_awready;
            m1_awready = s_awready & (!m0_awvalid);
            m0_wready = s_wready;
            m1_wready = s_wready & (!m0_wvalid);
        end

        S_WAIT_WREADY_M0: begin
            m0_wready = s_wready;
            s_wstrb = m0_wstrb;
            s_wvalid = m0_wvalid;
            s_wdata = m0_wdata;
        end

        S_WAIT_WREADY_M1: begin
            m1_wready = s_wready;
            s_wstrb = m1_wstrb;
            s_wvalid = m1_wvalid;
            s_wdata = m1_wdata;
        end

        S_WAIT_BVALID_M0: begin
            m0_bresp = s_bresp;
            m0_bvalid = s_bvalid;
            s_bready = m0_bready;
        end
        
        S_WAIT_BVALID_M1: begin
            m1_bresp = s_bresp;
            m1_bvalid = s_bvalid;
            s_bready = m1_bready;
        end

        default: begin
            // 在默认分支中，所有信号已经赋值为0
        end
    endcase
end

endmodule
