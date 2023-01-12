`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/01 14:50:16
// Design Name: 
// Module Name: decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module decoder(
    input wire[31:0] instr,
    output wire[3:0] memwrite,memtoreg,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,jumptoreg,
	output wire[5:0] label,
    output reg divstart,
    output reg isindelayslot,cp0write,cp0read,
    output reg [31:0] excepttype
    );

    wire[5:0] op,funct;
    wire[4:0] branchfunct,c0funct;

    assign op = instr[31:26];
	assign funct = instr[5:0];
    assign branchfunct = instr[20:16];
	assign c0funct = instr[25:21];

    reg[18:0] controls;
	assign {regwrite,regdst,alusrc,branch,jump,memwrite,memtoreg,label} = controls;
    always @(*) begin
        divstart<=0;
        isindelayslot<=0;
        cp0write<=0;
        cp0read<=0;
        excepttype<=0;
        if (instr==32'b0) controls<={5'b00000,4'b0000,4'b0000,6'b000000};  //空指令
        else begin
            case (op)
                6'b000000: begin
                    case (funct)
                        6'b100100: controls<={5'b11000,4'b0000,4'b0000,6'b001111};  //AND
                        6'b100101: controls<={5'b11000,4'b0000,4'b0000,6'b010011};  //OR
                        6'b100110: controls<={5'b11000,4'b0000,4'b0000,6'b010101};  //XOR
                        6'b100111: controls<={5'b11000,4'b0000,4'b0000,6'b010010};  //NOR 

                        6'b000100: controls<={5'b11000,4'b0000,4'b0000,6'b010111};  //SLLV
                        6'b000000: controls<={5'b11000,4'b0000,4'b0000,6'b011000};  //SLL
                        6'b000111: controls<={5'b11000,4'b0000,4'b0000,6'b011001}; //SRAV
                        6'b000011: controls<={5'b11000,4'b0000,4'b0000,6'b011010}; //SRA
                        6'b000110: controls<={5'b11000,4'b0000,4'b0000,6'b011011}; //SRLV
                        6'b000010: controls<={5'b11000,4'b0000,4'b0000,6'b011100}; //SRL

                        6'b010000: controls<={5'b11000,4'b0000,4'b0000,6'b101001};  //MFHI
                        6'b010010: controls<={5'b11000,4'b0000,4'b0000,6'b101010};  //MFLO
                        6'b010001: controls<={5'b00000,4'b0000,4'b0000,6'b101011};  //MTHI
                        6'b010011: controls<={5'b00000,4'b0000,4'b0000,6'b101100};  //MTLO
                        
                        6'b100000: controls<={5'b11000,4'b0000,4'b0000,6'b000001};  //ADD
                        6'b100001: controls<={5'b11000,4'b0000,4'b0000,6'b000011};  //ADDU
                        6'b100010: controls<={5'b11000,4'b0000,4'b0000,6'b000101};  //SUB
                        6'b100011: controls<={5'b11000,4'b0000,4'b0000,6'b000110};  //SUBU
                        6'b101010: controls<={5'b11000,4'b0000,4'b0000,6'b000111};  //SLT
                        6'b101011: controls<={5'b11000,4'b0000,4'b0000,6'b001001};  //SLTU
                        6'b011000: controls<={5'b00000,4'b0000,4'b0000,6'b001101};  //MULT
                        6'b011001: controls<={5'b00000,4'b0000,4'b0000,6'b001110};  //MULTU
                        6'b011010: begin  //DIV
                            controls<={5'b00000,4'b0000,4'b0000,6'b001011};
                            divstart<=1'b1;
                        end
                        6'b011011: begin  //DIVU
                            controls<={5'b00000,4'b0000,4'b0000,6'b001100}; 
                            divstart<=1'b1;
                        end

                        6'b001000: begin  //JR
                            controls<={5'b00001,4'b0000,4'b0000,6'b100111}; 
                            isindelayslot<=1'b1;
                        end
                        6'b001001: begin  //JALR
                            controls<={5'b11001,4'b0000,4'b0000,6'b101000};  
                            isindelayslot<=1'b1;
                        end

                        6'b001101: begin  //BREAK
                            controls<={5'b00000,4'b0000,4'b0000,6'b101101};
                            excepttype<=32'h00000009;
                        end
                        6'b001100: begin  //SYSCALL
                            controls<={5'b00000,4'b0000,4'b0000,6'b101110};
                            excepttype<=32'h00000008;
                        end

                        default: begin  //非法指令
                            controls<={5'b00000,4'b0000,4'b0000,6'b000000}; 
                            excepttype<=32'h0000000a;
                        end
                    endcase
                end
                6'b001100: controls<={5'b10100,4'b0000,4'b0000,6'b010000};  //ANDI
                6'b001101: controls<={5'b10100,4'b0000,4'b0000,6'b010100};  //ORI
                6'b001110: controls<={5'b10100,4'b0000,4'b0000,6'b010110};  //XORI
                6'b001111: controls<={5'b10100,4'b0000,4'b0000,6'b010001};  //LUI

                6'b001000: controls<={5'b10100,4'b0000,4'b0000,6'b000010};  //ADDI
                6'b001001: controls<={5'b10100,4'b0000,4'b0000,6'b000100};  //ADDIU
                6'b001010: controls<={5'b10100,4'b0000,4'b0000,6'b001000};  //SLTI
                6'b001011: controls<={5'b10100,4'b0000,4'b0000,6'b001010};  //SLTIU

                6'b000100: begin  //BEQ
                    controls<={5'b00010,4'b0000,4'b0000,6'b011101};
                    isindelayslot<=1'b1;
                end
                6'b000101: begin  //BNE
                    controls<={5'b00010,4'b0000,4'b0000,6'b011110}; 
                    isindelayslot<=1'b1;
                end
                6'b000001: begin
                    case (branchfunct)
                        5'b00001: begin  //BGEZ
                            controls<={5'b00010,4'b0000,4'b0000,6'b011111};
                            isindelayslot<=1'b1;
                        end
                        5'b00000: begin  //BLTZ
                            controls<={5'b00010,4'b0000,4'b0000,6'b100010};
                            isindelayslot<=1'b1;
                        end
                        5'b10001: begin  //BGEZAL 
                            controls<={5'b10010,4'b0000,4'b0000,6'b100011};
                            isindelayslot<=1'b1;
                        end
                        5'b10000: begin  //BLTZAL
                            controls<={5'b10010,4'b0000,4'b0000,6'b100100};
                            isindelayslot<=1'b1;
                        end
                        default: begin  //非法指令
                            controls<={5'b00000,4'b0000,4'b0000,6'b000000}; 
                            excepttype<=32'h0000000a;
                        end
                    endcase
                end
                6'b000111: begin  //BGTZ
                    controls<={5'b00010,4'b0000,4'b0000,6'b100000};
                    isindelayslot<=1'b1;
                end
                6'b000110: begin  //BLEZ
                    controls<={5'b00010,4'b0000,4'b0000,6'b100001};
                    isindelayslot<=1'b1;
                end
                6'b000010: begin  //J 
                    controls<={5'b00001,4'b0000,4'b0000,6'b100101};
                    isindelayslot<=1'b1;
                end
                6'b000011: begin  //JAL 
                    controls<={5'b10001,4'b0000,4'b0000,6'b100110};
                    isindelayslot<=1'b1;
                end

                6'b100000: controls<={5'b10100,4'b0000,4'b1001,6'b101111};  //LB
                6'b100100: controls<={5'b10100,4'b0000,4'b0001,6'b110000};  //LBU
                6'b100001: controls<={5'b10100,4'b0000,4'b1011,6'b110001};  //LH
                6'b100101: controls<={5'b10100,4'b0000,4'b0011,6'b110010};  //LHU
                6'b100011: controls<={5'b10100,4'b0000,4'b1111,6'b110011};  //LW
                6'b101000: controls<={5'b00100,4'b0001,4'b0000,6'b110100};  //SB
                6'b101001: controls<={5'b00100,4'b0011,4'b0000,6'b110101};  //SH
                6'b101011: controls<={5'b00100,4'b1111,4'b0000,6'b110110};  //SW

                6'b010000: begin
                    case (c0funct)
                        5'b00000: begin  //MFC0 
                            controls<={5'b10000,4'b0000,4'b0000,6'b111000}; 
                            cp0read<=1'b1; 
                        end 
                        5'b00100: begin  //MTC0
                            controls<={5'b00000,4'b0000,4'b0000,6'b111001};
                            cp0write<=1'b1;
                        end
                        default: begin
                            case (funct)
                                6'b011000: begin  //ERET
                                    controls<={5'b00000,4'b0000,4'b0000,6'b110111};
                                    excepttype<=32'h0000000e;
                                end
                                default: begin  //非法指令
                                    controls<={5'b00000,4'b0000,4'b0000,6'b000000}; 
                                    excepttype<=32'h0000000a;
                                end
                            endcase
                        end
                    endcase
                end

                default: begin  //非法指令
                    controls<={5'b00000,4'b0000,4'b0000,6'b000000}; 
                    excepttype<=32'h0000000a;
                end
            endcase
        end
    end

endmodule
