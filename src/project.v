`default_nettype none

module tt_um_lixiaobo_1d_cnn (
    input  wire [7:0] ui_in,    // 外部输入：可以是加速度计的 8-bit 数据
    output wire [7:0] uo_out,   // 外部输出：分类结果或处理后的特征
    input  wire [7:0] uio_in,   // 双向 IO 入
    output wire [7:0] uio_out,  // 双向 IO 出
    output wire [7:0] uio_oe,   // 双向 IO 使能
    input  wire       ena,      // 设计使能
    input  wire       clk,      // 时钟
    input  wire       rst_n     // 复位 (低电平有效)
);

    // --- 1. 内部寄存器：3点滑动窗口 ---
    reg [7:0] shift_reg [0:2];
    
    // --- 2. 卷积权重 (示例：[1, 2, 1] 高斯平滑滤波) ---
    // 在硬件中，乘以 2 等于左移 1 位，不消耗逻辑门
    wire [10:0] conv_result; 

    always @(posedge clk) begin
        if (!rst_n) begin
            shift_reg[0] <= 8'b0;
            shift_reg[1] <= 8'b0;
            shift_reg[2] <= 8'b0;
        end else if (ena) begin
            // 每一个时钟周期移动一次（实际应配合 Data_Ready 信号）
            shift_reg[0] <= ui_in;
            shift_reg[1] <= shift_reg[0];
            shift_reg[2] <= shift_reg[1];
        end
    end

    // --- 3. 卷积运算：Sum = (D0*1 + D1*2 + D2*1) ---
    // 这是最基础的 1D 卷积逻辑
    assign conv_result = (shift_reg[0]) + (shift_reg[1] << 1) + (shift_reg[2]);

    // --- 4. 激活函数/输出映射 ---
    // 这里简单地取高位作为输出，或者你可以加一个阈值判断 (ReLU)
    assign uo_out = conv_result[9:2]; 

    // 未使用的 IO 置零
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

endmodule
