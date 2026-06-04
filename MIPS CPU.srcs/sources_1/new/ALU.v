`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: ALU
// Description: 算术逻辑单元
//              支持加减、逻辑运算、移位、比较等操作
// Operations: ADD/ADDU, SUB/SUBU, AND, OR, XOR, NOR, LUI, SLT/SLTU, SLL, SRL, SRA
//////////////////////////////////////////////////////////////////////////////////

module ALU(
    input             ALUSrcA,   // 操作数 A 来源 (0:DataInA, 1:sa)
    input             ALUSrcB,   // 操作数 B 来源 (0:DataInB, 1:extend)
    input      [4:0]  sa,        // 移位量 (Shift Amount)
    input      [31:0] extend,    // 扩展后的立即数
    input      [31:0] DataInA,   // 输入数据 A
    input      [31:0] DataInB,   // 输入数据 B
    input      [3:0]  ALUop,     // ALU 操作码
    output reg        ZeroFlag,  // 零标志 (结果为 0 时置 1)
    output reg [31:0] DataOut    // 运算结果
);

    reg [31:0] A, B;

    always @(*) begin
        // 操作数选择
        A = (ALUSrcA == 1'b0) ? DataInA : {27'd0, sa};
        B = (ALUSrcB == 1'b0) ? DataInB : extend;

        // ALU 运算
        case (ALUop)
            4'b0000, 4'b0010: begin
                // ADDU / ADD - 加法
                DataOut = A + B;
            end
            4'b0001, 4'b0011: begin
                // SUBU / SUB - 减法
                DataOut = A - B;
            end
            4'b0100: begin
                // AND - 按位与
                DataOut = A & B;
            end
            4'b0101: begin
                // OR - 按位或
                DataOut = A | B;
            end
            4'b0110: begin
                // XOR - 按位异或
                DataOut = A ^ B;
            end
            4'b0111: begin
                // NOR - 按位或非
                DataOut = ~(A | B);
            end
            4'b1000, 4'b1001: begin
                // LUI - 立即数加载到高 16 位
                DataOut = {B[15:0], 16'd0};
            end
            4'b1011: begin
                // SLT - 有符号小于比较
                case ({A[31], B[31]})
                    2'b01: DataOut = 32'd0;   // A正B负, A > B
                    2'b10: DataOut = 32'd1;   // A负B正, A < B
                    default: DataOut = (A[30:0] < B[30:0]) ? 32'd1 : 32'd0;
                endcase
            end
            4'b1010: begin
                // SLTU - 无符号小于比较
                DataOut = (A < B) ? 32'd1 : 32'd0;
            end
            4'b1100: begin
                // SRA - 算术右移
                DataOut = $signed(B) >>> A[4:0];
            end
            4'b1110: begin
                // SLL - 逻辑左移
                DataOut = B << A[4:0];
            end
            4'b1101: begin
                // SRL - 逻辑右移
                DataOut = B >> A[4:0];
            end
            default: DataOut = 32'd0;
        endcase

        // 零标志
        ZeroFlag = ~(|DataOut);
    end

endmodule
