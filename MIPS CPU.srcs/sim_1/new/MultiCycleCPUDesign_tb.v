`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: MultiCycleCPUDesign_tb
// Description: MIPS 多周期 CPU 测试平台
//              生成时钟和复位信号，实例化 CPU 并观察运行状态
// Usage: 在 Vivado 中运行仿真，观察波形
//////////////////////////////////////////////////////////////////////////////////

module MultiCycleCPUDesign_tb;

    // 时钟和复位信号
    reg clk, rst;

    // 复位信号: 前 50ns 为高电平
    initial begin
        rst = 1;
        #50 rst = 0;
    end

    // 时钟信号: 周期 10ns (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // CPU 输出信号连线
    wire [31:0] curPC, nextPC, inst, IRinst;
    wire [5:0]  op, func;
    wire [4:0]  rs, rt, rd;
    wire [31:0] DB, dataDB;
    wire [31:0] A, dataA, B, dataB;
    wire [31:0] result, dataResult;
    wire [1:0]  PCSource, RegDst;
    wire        ZeroFlag, PCWr, IsRd;
    wire        RegWr, ALUSrcA, ALUSrcB;
    wire [3:0]  ALUop;
    wire        MemRd, MemWr, DBDataSrc, WrRegDSrc;
    wire [31:0] Rw, extend;
    wire [2:0]  cur_state;

    // 实例化 CPU
    CPU_main CPU(
        .clk(clk),
        .rst(rst),
        .curPC(curPC),
        .nextPC(nextPC),
        .inst(inst),
        .IRinst(IRinst),
        .op(op),
        .func(func),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .DB(DB),
        .dataDB(dataDB),
        .A(A),
        .dataA(dataA),
        .B(B),
        .dataB(dataB),
        .result(result),
        .dataResult(dataResult),
        .PCSource(PCSource),
        .ZeroFlag(ZeroFlag),
        .PCWr(PCWr),
        .IsRd(IsRd),
        .RegDst(RegDst),
        .RegWr(RegWr),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ALUop(ALUop),
        .MemRd(MemRd),
        .MemWr(MemWr),
        .DBDataSrc(DBDataSrc),
        .WrRegDSrc(WrRegDSrc),
        .Rw(Rw),
        .cur_state(cur_state),
        .extend(extend)
    );

endmodule
