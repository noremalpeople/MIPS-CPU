`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: RegFile
// Description: 寄存器文件
//              包含 32 个 32 位寄存器，$0 恒为 0
//              支持双端口读和单端口写 (下降沿触发)
// RegDst 写地址选择:
//   00 - $ra (31) - 用于 JAL
//   01 - rt      - 用于 I-type 指令
//   10 - rd      - 用于 R-type 指令
//////////////////////////////////////////////////////////////////////////////////

module RegFile(
    input             clk,       // 时钟
    input             RegWr,     // 写使能
    input      [1:0]  RegDst,    // 写地址选择
    input      [4:0]  Ra,        // 读地址 1 (rs)
    input      [4:0]  Rb,        // 读地址 2 (rt)
    input      [4:0]  Rd,        // rd 字段
    input      [31:0] Dw,        // 写入数据
    output     [31:0] Da,        // 读出数据 1
    output     [31:0] Db,        // 读出数据 2
    output reg [31:0] Rw         // 写地址
);

    reg [31:0] regfile [31:0];  // 32 个 32 位寄存器

    // 初始化所有寄存器为 0
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regfile[i] = 32'd0;
    end

    // 读操作 (组合逻辑，立即生效)
    assign Da = regfile[Ra];
    assign Db = regfile[Rb];

    // 写地址选择
    always @(*) begin
        case (RegDst)
            2'b00: Rw = 5'd31;   // $ra
            2'b01: Rw = Rb;      // rt
            2'b10: Rw = Rd;      // rd
            default: Rw = 5'd0;
        endcase
    end

    // 写操作 (下降沿触发，$0 不可写)
    always @(negedge clk) begin
        if (RegWr && Rw != 5'd0)
            regfile[Rw] <= Dw;
    end

endmodule
