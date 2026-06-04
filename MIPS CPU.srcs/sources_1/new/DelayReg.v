`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: DelayReg
// Description: 延迟寄存器
//              在时钟下降沿锁存输入数据，用于多周期 CPU 的数据暂存
//////////////////////////////////////////////////////////////////////////////////

module DelayReg(
    input             clk,       // 时钟
    input      [31:0] IData,     // 输入数据
    output reg [31:0] OData      // 输出数据
);

    always @(negedge clk) begin
        OData <= IData;
    end

endmodule
