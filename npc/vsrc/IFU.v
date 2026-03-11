// IFU：高性能取指单元，一段式状态机实现，带宏定义的取指延迟打印
module IFU (
  input  wire clk,
  input  wire rst,

  input  wire [31:0] pc,            
  input  wire [31:0] redirect_pc,   
  input  wire flush,

  // BPU (combinational predict for current req_pc)
  input  wire        bpu_taken,
  input  wire [31:0] bpu_target,

  // AXI4-lite
  output wire [31:0] araddr,
  output wire arvalid,
  input  wire arready,
  output wire [2:0]  arsize,

  input  wire [31:0] rdata,
  input  wire [1:0]  rresp,
  input  wire rvalid,
  output wire rready,

  input  wire ready_in_idu,        
  output wire valid_out_idu,       
  output reg  [31:0] pc_buf,
  output reg  [31:0] inst,

  // predicted next pc for this instruction (dnpc predicted by IFU)
  output reg  [31:0] pred_next_pc_buf
);

// ========== 状态定义 ==========
localparam [1:0] WAIT_ADDR = 2'b00,
                 WAIT_DATA = 2'b01,
                 WAIT_IDU  = 2'b10;

reg [1:0] state; 

// 独立取指指针与缓存
reg [31:0] req_pc;

reg if_valid;
reg kill_resp;

// outstanding request's predicted next pc (latched on address handshake)
reg [31:0] req_pred_next_pc;

`ifdef DEBUG_ON
// 【计时器】：内部累加器，仅在 DEBUG_ON 时编译
reg [31:0] timer;
`endif

// ========== 静态信号输出 ==========
assign arsize  = 3'b010; 
assign araddr  = req_pc;
assign arvalid = (state == WAIT_ADDR) && ~rst;
assign rready  = (state == WAIT_DATA);

// 对外接口信号
assign valid_out_idu = if_valid && ~flush;

// ========== 核心控制逻辑 (一段式状态机) ==========
always @(posedge clk) begin
  if (rst) begin
    state        <= WAIT_ADDR;
    req_pc       <= pc;
    pc_buf       <= 32'b0;
    inst         <= 32'b0;
    if_valid     <= 1'b0;
    kill_resp    <= 1'b0;

    pred_next_pc_buf <= 32'b0;
    
`ifdef DEBUG_ON
    timer        <= 32'd0;
`endif
  end 
  else begin
    // -----------------------------------------------------------------
    // 分支 1：最高优先级处理 Flush 冲刷
    // -----------------------------------------------------------------
    if (flush) begin
      if_valid <= 1'b0; 
      
      if (state == WAIT_IDU) begin
        // 总线空闲，直接切换地址并发起新请求
        state      <= WAIT_ADDR;
        req_pc     <= redirect_pc;
        kill_resp  <= 1'b0;

        
`ifdef DEBUG_ON
        timer      <= 32'd0; // 发起了新请求，重新开始计时
`endif
      end 
      else begin
        // 总线正忙，只能先存下目标 PC
        req_pred_next_pc <= redirect_pc; 
        
        // 如果正好此时废弃数据回来了，下一拍可以直接发新请求
        if (state == WAIT_DATA && rvalid) begin
          kill_resp  <= 1'b0;
          state      <= WAIT_ADDR;
          req_pc     <= redirect_pc;
          
`ifdef DEBUG_ON
          timer      <= 32'd0; // 发起了新请求，重新开始计时
`endif
        end 

         else if (state == WAIT_ADDR && arready) begin
          state     <= WAIT_DATA; // 握手已发生，必须跳到 WAIT_DATA 等待数据返回
          kill_resp <= 1'b1;      // 标记即将返回的数据为废弃数据
`ifdef DEBUG_ON
          timer     <= timer + 32'd1; // 废弃请求仍在路上，维持计时器运转
`endif
        end

        else begin
          kill_resp <= 1'b1; 
`ifdef DEBUG_ON
          timer     <= timer + 32'd1; // 废弃请求仍在路上，维持计时器运转
`endif
        end
      end
    end 
    // -----------------------------------------------------------------
    // 分支 2：正常状态流转与数据通路
    // -----------------------------------------------------------------
    else begin
      // A. 下游握手成功，清空当前阶段的有效位
      if (valid_out_idu && ready_in_idu) begin
        if_valid <= 1'b0;
      end

      // B. 状态机流转
      case (state)
        WAIT_ADDR: begin
`ifdef DEBUG_ON
          timer <= timer + 32'd1; // 等待地址握手，累加
`endif
          if (arready) begin
            state <= WAIT_DATA;

            // compute and latch predicted next pc for this request (dnpc)
            req_pred_next_pc <= bpu_taken ? bpu_target : (req_pc + 32'd4);
          end
        end
        
        WAIT_DATA: begin
          if (rvalid) begin
            if (kill_resp) begin
              // 废弃数据返回：丢掉它，立刻去取缓存的新地址
              kill_resp  <= 1'b0;
              state      <= WAIT_ADDR;
              req_pc     <= req_pred_next_pc;
              
`ifdef DEBUG_ON
              timer      <= 32'd0; // 抛弃旧请求，发出新请求，清零！
`endif
            end 
            else begin
              // 有效数据返回：锁存数据，进入等待 IDU 接收状态
              pc_buf       <= req_pc;
              inst         <= rdata;
              if_valid     <= 1'b1;
              state        <= WAIT_IDU;

              pred_next_pc_buf <= req_pred_next_pc;
              
`ifdef DEBUG_ON
              // 成功拿到指令！当前 timer 值加上这一拍，就是总延迟
              $display("[IFU Timer] Fetch PC: 0x%08x | Cycles taken: %0d", req_pc, timer + 32'd1);
`endif
            end
          end 
          else begin
`ifdef DEBUG_ON
            timer <= timer + 32'd1; // 等待数据返回，累加
`endif
          end
        end
        
        WAIT_IDU: begin
          // 数据已被接收：立刻切回 WAIT_ADDR，发起下一次取指
          if (ready_in_idu) begin
            state      <= WAIT_ADDR;
            req_pc     <= req_pred_next_pc;
            
`ifdef DEBUG_ON
            timer      <= 32'd0; // 发出下一条指令取指请求，清零！
`endif
          end
        end
      endcase
    end
  end
end
/*
always@(posedge clk)
  $display("IFU CURRENT state: %x arready: %x, flush %x, arvalid %x", state, arready, flush, arvalid);
*/

endmodule
