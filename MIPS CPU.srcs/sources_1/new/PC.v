`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: PC
// Description: 程序计数器 (Program Counter)
//              在时钟下降沿更新，支持复位和写使能控制
//////////////////////////////////////////////////////////////////////////////////

module PC(
    input             clk,       // 时钟
    input             rst,       // 复位信号
    input             PCWr,      // 写使能
    input      [31:0] next_PC,   // 下一 PC 值
    output reg [31:0] cur_PC     // 当前 PC 值
);

    initial begin
        cur_PC = 32'd0;
    end

    always @(negedge clk) begin
        if (rst)
            cur_PC <= 32'd0;
        else if (PCWr)
            cur_PC <= next_PC;
    end

endmodule
