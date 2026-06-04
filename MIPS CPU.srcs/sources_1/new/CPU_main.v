`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: CPU_main
// Description: MIPS 多周期 CPU 顶层模块
//              连接所有子模块，构成完整的数据通路
// Architecture: 多周期实现，包含 IF/ID/EXE/MEM/WB 五个阶段
//////////////////////////////////////////////////////////////////////////////////

module CPU_main(
    input         clk,
    input         rst,
    // 调试输出信号
    output [31:0] curPC,        // 当前 PC 值
    output [31:0] nextPC,       // 下一 PC 值
    output [31:0] inst,         // 从 ROM 读取的指令
    output [31:0] IRinst,       // 指令寄存器中的指令
    output [5:0]  op, func,     // 操作码和功能码
    output [4:0]  rs, rt, rd,   // 寄存器地址
    output [31:0] DB,           // 数据总线
    output [31:0] dataDB,       // 数据总线延迟值
    output [31:0] A, dataA, B, dataB,  // 寄存器读出数据及延迟值
    output [31:0] result,       // ALU 运算结果
    output [31:0] dataResult,   // ALU 结果延迟值
    output [1:0]  PCSource,     // PC 来源选择
    output        ZeroFlag,     // ALU 零标志
    output        PCWr,         // PC 写使能
    output        IsRd,         // ROM 读使能
    output [1:0]  RegDst,       // 写寄存器地址选择
    output        RegWr,        // 寄存器写使能
    output        ALUSrcA,      // ALU 操作数 A 来源
    output        ALUSrcB,      // ALU 操作数 B 来源
    output [3:0]  ALUop,        // ALU 操作类型
    output        MemRd, MemWr, // 存储器读/写使能
    output        DBDataSrc,    // 数据总线来源选择
    output        WrRegDSrc,    // 写寄存器数据来源
    output [31:0] Rw,           // 写寄存器地址
    output [31:0] extend,       // 符号扩展后的立即数
    output [2:0]  cur_state     // 当前状态机状态
);

    // 内部连线
    wire [31:0] DataOut;
    wire [4:0]  sa;
    wire [15:0] imm16;
    wire [25:0] addr;
    wire        IRWr, ExtType;

    //=========================================
    // 控制单元 - 生成所有控制信号
    //=========================================
    ControlUnit control_unit(
        .clk(clk),
        .rst(rst),
        .ZeroFlag(ZeroFlag),
        .op(op),
        .func(func),
        .PCWr(PCWr),
        .PCSource(PCSource),
        .IRWr(IRWr),
        .ExtType(ExtType),
        .IsRd(IsRd),
        .MemRd(MemRd),
        .MemWr(MemWr),
        .RegWr(RegWr),
        .RegDst(RegDst),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ALUop(ALUop),
        .WrRegDSrc(WrRegDSrc),
        .DBDataSrc(DBDataSrc),
        .cur_state(cur_state)
    );

    //=========================================
    // PC 模块 - 程序计数器
    //=========================================
    PC pc(
        .clk(clk),
        .rst(rst),
        .PCWr(PCWr),
        .next_PC(nextPC),
        .cur_PC(curPC)
    );

    //=========================================
    // PC_next 模块 - 计算下一 PC 值
    //=========================================
    PC_next pc_next(
        .rst(rst),
        .cur_PC(curPC),
        .PCSource(PCSource),
        .imm16(extend),
        .rs(A),
        .addr(addr),
        .next_PC(nextPC)
    );

    //=========================================
    // ROM 模块 - 指令存储器
    //=========================================
    ROM rom(
        .IsRd(IsRd),
        .addr(curPC),
        .DataOut(inst)
    );

    //=========================================
    // IR 模块 - 指令寄存器
    //=========================================
    IR ir(
        .clk(clk),
        .IRWr(IRWr),
        .next_inst(inst),
        .cur_inst(IRinst)
    );

    //=========================================
    // InstSplit 模块 - 指令字段分割
    //=========================================
    InstSplit inst_split(
        .inst(IRinst),
        .op(op),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .sa(sa),
        .func(func),
        .imm16(imm16),
        .addr(addr)
    );

    //=========================================
    // Extend 模块 - 立即数符号/零扩展
    //=========================================
    Extend extend16to32(
        .imm16(imm16),
        .ExtType(ExtType),
        .imm32(extend)
    );

    //=========================================
    // RegFile 模块 - 32 个 32 位寄存器
    //=========================================
    RegFile regfile(
        .clk(clk),
        .RegWr(RegWr),
        .RegDst(RegDst),
        .Ra(rs),
        .Rb(rt),
        .Rd(rd),
        .Dw(WrRegDSrc ? dataDB : curPC + 4),
        .Da(A),
        .Db(B),
        .Rw(Rw)
    );

    //=========================================
    // ALU 模块 - 算术逻辑单元
    //=========================================
    ALU alu(
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .sa(sa),
        .extend(extend),
        .DataInA(dataA),
        .DataInB(dataB),
        .ALUop(ALUop),
        .ZeroFlag(ZeroFlag),
        .DataOut(result)
    );

    //=========================================
    // RAM 模块 - 数据存储器
    //=========================================
    RAM ram(
        .MemRd(MemRd),
        .MemWr(MemWr),
        .addr(result),
        .data_in(dataB),
        .data_out(DataOut),
        .DB(DB),
        .DBDataSrc(DBDataSrc)
    );

    //=========================================
    // 延迟寄存器 - 用于多周期数据暂存
    //=========================================
    DelayReg ADR(
        .clk(clk),
        .IData(A),
        .OData(dataA)
    );

    DelayReg BDR(
        .clk(clk),
        .IData(B),
        .OData(dataB)
    );

    DelayReg ALUoutDR(
        .clk(clk),
        .IData(result),
        .OData(dataResult)
    );

    DelayReg DBDR(
        .clk(clk),
        .IData(DB),
        .OData(dataDB)
    );

endmodule
