`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: ControlUnit
// Description: MIPS 多周期 CPU 控制单元
//              实现有限状态机，根据指令类型生成控制信号
// States: INIT -> IF -> ID -> EXE -> MEM -> WB
//////////////////////////////////////////////////////////////////////////////////

module ControlUnit(
    input             clk,
    input             rst,
    input             ZeroFlag,     // ALU 零标志
    input      [5:0]  op,           // 操作码
    input      [5:0]  func,         // 功能码
    // 控制信号输出
    output reg        PCWr,         // PC 写使能
    output reg [1:0]  PCSource,     // PC 来源选择
    output reg        IRWr,         // 指令寄存器写使能
    output reg        ExtType,      // 扩展类型 (0:零扩展, 1:符号扩展)
    output reg        IsRd,         // ROM 读使能
    output reg        MemRd,        // RAM 读使能
    output reg        MemWr,        // RAM 写使能
    output reg        RegWr,        // 寄存器写使能
    output reg [1:0]  RegDst,       // 写寄存器地址选择
    output reg        ALUSrcA,      // ALU 操作数 A 来源
    output reg        ALUSrcB,      // ALU 操作数 B 来源
    output reg [3:0]  ALUop,        // ALU 操作类型
    output reg        WrRegDSrc,    // 写寄存器数据来源
    output reg        DBDataSrc,    // 数据总线来源
    output      [2:0] cur_state     // 当前状态 (用于调试)
);

    //=========================================
    // 指令类型判断
    //=========================================
    // R-type 指令
    wire I_ADD  = (op == 6'b000000 && func == 6'b100000);
    wire I_ADDU = (op == 6'b000000 && func == 6'b100001);
    wire I_SUB  = (op == 6'b000000 && func == 6'b100010);
    wire I_SUBU = (op == 6'b000000 && func == 6'b100011);
    wire I_AND  = (op == 6'b000000 && func == 6'b100100);
    wire I_OR   = (op == 6'b000000 && func == 6'b100101);
    wire I_XOR  = (op == 6'b000000 && func == 6'b100110);
    wire I_NOR  = (op == 6'b000000 && func == 6'b100111);
    wire I_SLT  = (op == 6'b000000 && func == 6'b101010);
    wire I_SLTU = (op == 6'b000000 && func == 6'b101011);
    wire I_SLL  = (op == 6'b000000 && func == 6'b000000);
    wire I_SRL  = (op == 6'b000000 && func == 6'b000010);
    wire I_SRA  = (op == 6'b000000 && func == 6'b000011);
    wire I_SLLV = (op == 6'b000000 && func == 6'b000100);
    wire I_SRLV = (op == 6'b000000 && func == 6'b000110);
    wire I_SRAV = (op == 6'b000000 && func == 6'b000111);
    wire I_JR   = (op == 6'b000000 && func == 6'b001000);

    // I-type 指令
    wire I_ADDI  = (op == 6'b001000);
    wire I_ADDIU = (op == 6'b001001);
    wire I_ANDI  = (op == 6'b001100);
    wire I_ORI   = (op == 6'b001101);
    wire I_XORI  = (op == 6'b001110);
    wire I_LUI   = (op == 6'b001111);
    wire I_LW    = (op == 6'b100011);
    wire I_SW    = (op == 6'b101011);
    wire I_BEQ   = (op == 6'b000100);
    wire I_BNE   = (op == 6'b000101);
    wire I_SLTI  = (op == 6'b001010);
    wire I_SLTIU = (op == 6'b001011);

    // J-type 指令
    wire I_J   = (op == 6'b000010);
    wire I_JAL = (op == 6'b000011);

    //=========================================
    // ALU 操作类型定义
    //=========================================
    localparam ALU_ADD  = 4'b0010;
    localparam ALU_ADDU = 4'b0000;
    localparam ALU_SUB  = 4'b0011;
    localparam ALU_SUBU = 4'b0001;
    localparam ALU_AND  = 4'b0100;
    localparam ALU_OR   = 4'b0101;
    localparam ALU_XOR  = 4'b0110;
    localparam ALU_NOR  = 4'b0111;
    localparam ALU_LUI  = 4'b1000;
    localparam ALU_SLT  = 4'b1011;
    localparam ALU_SLTU = 4'b1010;
    localparam ALU_SRA  = 4'b1100;
    localparam ALU_SLL  = 4'b1110;
    localparam ALU_SRL  = 4'b1101;

    //=========================================
    // 状态机定义
    //=========================================
    reg [2:0] state, next_state;
    localparam sINIT = 3'd0;  // 初始化状态
    localparam sIF   = 3'd1;  // 取指阶段
    localparam sID   = 3'd2;  // 译码阶段
    localparam sEXE  = 3'd3;  // 执行阶段
    localparam sMEM  = 3'd4;  // 访存阶段
    localparam sWB   = 3'd5;  // 写回阶段

    // 初始化
    initial begin
        state      = sINIT;
        PCWr       = 0;
        PCSource   = 0;
        IRWr       = 0;
        ExtType    = 0;
        IsRd       = 0;
        MemRd      = 0;
        MemWr      = 0;
        RegWr      = 0;
        RegDst     = 2'b11;
        ALUSrcA    = 0;
        ALUSrcB    = 0;
        ALUop      = 0;
        WrRegDSrc  = 0;
        DBDataSrc  = 0;
    end

    // 状态转移 (下降沿触发)
    always @(negedge clk) begin
        if (rst)
            state <= sINIT;
        else
            state <= next_state;
    end

    //=========================================
    // 次态逻辑
    //=========================================
    always @(*) begin
        case (state)
            sINIT: next_state = sIF;
            sIF:   next_state = sID;
            sID: begin
                if (I_J || I_JAL || I_JR)
                    next_state = sIF;
                else
                    next_state = sEXE;
            end
            sEXE: begin
                if (I_BEQ || I_BNE)
                    next_state = sIF;
                else if (I_SW || I_LW)
                    next_state = sMEM;
                else
                    next_state = sWB;
            end
            sMEM: begin
                if (I_SW)
                    next_state = sIF;
                else
                    next_state = sWB;
            end
            sWB: next_state = sIF;
            default: next_state = sIF;
        endcase
    end

    //=========================================
    // 控制信号生成
    //=========================================
    always @(*) begin
        // ---- IsRd: ROM 读使能 ----
        IsRd = (state == sIF);

        // ---- PCWr: PC 写使能 ----
        PCWr = (next_state == sIF);

        // ---- IRWr: 指令寄存器写使能 ----
        IRWr = (state == sIF || next_state == sID);

        // ---- ALUSrcA: ALU 操作数 A 来源 ----
        // 移位指令使用 sa 字段，其他使用寄存器值
        ALUSrcA = (I_SLL || I_SRL || I_SRA);

        // ---- ALUSrcB: ALU 操作数 B 来源 ----
        // 立即数指令使用扩展后的立即数
        ALUSrcB = (I_ADDI || I_ADDIU || I_ANDI || I_ORI || I_XORI ||
                   I_LW || I_SW || I_SLTI || I_SLTIU || I_LUI);

        // ---- DBDataSrc: 数据总线来源 ----
        // LW 指令从 RAM 读取，其他从 ALU 结果
        DBDataSrc = I_LW;

        // ---- RegWr / RegDst / WrRegDSrc: 寄存器写控制 ----
        if ((state == sWB && !I_BEQ && !I_BNE && !I_SW) ||
            (state == sID && I_JAL)) begin
            RegWr = 1'b1;
            if (I_JAL) begin
                WrRegDSrc = 1'b0;  // JAL 保存 PC+4
                RegDst    = 2'b00;  // 写 $ra (寄存器 31)
            end else begin
                WrRegDSrc = 1'b1;  // 其他指令写 ALU/内存结果
                if (I_ADDI || I_ADDIU || I_ANDI || I_ORI || I_XORI ||
                    I_LW || I_SLTI || I_SLTIU || I_LUI)
                    RegDst = 2'b01;  // I-type: 写 rt
                else
                    RegDst = 2'b10;  // R-type: 写 rd
            end
        end else begin
            RegWr = 1'b0;
        end

        // ---- MemRd / MemWr: 存储器读写控制 ----
        MemRd = I_LW;
        MemWr = (state == sMEM && I_SW);

        // ---- ExtType: 扩展类型 ----
        // 需要符号扩展的指令
        ExtType = (I_ADDI || I_SW || I_LW || I_BEQ || I_BNE || I_SLTI);

        // ---- PCSource: PC 来源选择 ----
        if (I_JR)
            PCSource = 2'b10;  // 寄存器跳转
        else if ((ZeroFlag && I_BEQ) || (!ZeroFlag && I_BNE))
            PCSource = 2'b01;  // 条件分支
        else if (I_J || I_JAL)
            PCSource = 2'b11;  // 无条件跳转
        else
            PCSource = 2'b00;  // PC + 4

        // ---- ALUop: ALU 操作类型 ----
        if (op == 6'b000000) begin
            // R-type 指令
            case (func)
                6'b100000: ALUop = ALU_ADD;
                6'b100001: ALUop = ALU_ADDU;
                6'b100010: ALUop = ALU_SUB;
                6'b100011: ALUop = ALU_SUBU;
                6'b100100: ALUop = ALU_AND;
                6'b100101: ALUop = ALU_OR;
                6'b100110: ALUop = ALU_XOR;
                6'b100111: ALUop = ALU_NOR;
                6'b101010: ALUop = ALU_SLT;
                6'b101011: ALUop = ALU_SLTU;
                6'b000000, 6'b000100: ALUop = ALU_SLL;  // SLL, SLLV
                6'b000010, 6'b000110: ALUop = ALU_SRL;  // SRL, SRLV
                6'b000011, 6'b000111: ALUop = ALU_SRA;  // SRA, SRAV
                default: ALUop = ALU_ADD;
            endcase
        end else begin
            // I-type 指令
            case (op)
                6'b001000, 6'b101011, 6'b100011: ALUop = ALU_ADD;   // ADDI, SW, LW
                6'b001001: ALUop = ALU_ADDU;  // ADDIU
                6'b001100: ALUop = ALU_AND;   // ANDI
                6'b001101: ALUop = ALU_OR;    // ORI
                6'b001110: ALUop = ALU_XOR;   // XORI
                6'b001111: ALUop = ALU_LUI;   // LUI
                6'b000100, 6'b000101: ALUop = ALU_SUB;  // BEQ, BNE
                6'b001010: ALUop = ALU_SLT;   // SLTI
                6'b001011: ALUop = ALU_SLTU;  // SLTIU
                default: ALUop = ALU_ADD;
            endcase
        end
    end

    // 当前状态输出 (用于调试)
    assign cur_state = state;

endmodule
