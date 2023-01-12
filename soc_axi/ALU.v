`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/03 22:48:17
// Design Name: 
// Module Name: ALU
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


module ALU(
    input wire[31:0] a,b,
    input wire[4:0] sa,
    input wire[31:0] pcplus4,
    input wire[31:0] hi_o,lo_o,
    input wire[63:0] divres,
    input wire[5:0] label,
    input wire[31:0] readcp0data,
    output reg[31:0] y,
    output reg[31:0] hi_i,lo_i,
    output reg hilowe,reg31write,
    output wire[1:0] lbshift,
    output reg overflow
    );
    
    wire [31:0] addres,subres;
    assign addres=a+b;
    assign subres=a-b;
    wire [63:0] mulres,mulures;
    assign mulres=$signed(a)*$signed(b);
    assign mulures={32'b0,a}*{32'b0,b};

    assign lbshift=addres[1:0];
    
    always @(*) begin
        hilowe<=0;
        reg31write<=0;
        overflow<=0;
        case (label)
            6'b001111: y<=(a&b);  //AND
            6'b010000: y<=(a&b);  //ANDI
            6'b010001: y<=(b<<16);  //LUI
            6'b010010: y<=(~(a|b));  //NOR
            6'b010011: y<=(a|b);  //OR
            6'b010100: y<=(a|b);  //ORI
            6'b010101: y<=(a^b);  //XOR
            6'b010110: y<=(a^b);  //XORI

            6'b010111: y<=(b<<$unsigned(a[4:0]));  //SLLV
            6'b011000: y<=(b<<$unsigned(sa));  //SLL
            6'b011001: y<=($signed(b)>>>$unsigned(a[4:0]));  //SRAV
            6'b011010: y<=($signed(b)>>>$unsigned(sa));  //SRA
            6'b011011: y<=(b>>$unsigned(a[4:0]));  //SRLV
            6'b011100: y<=(b>>$unsigned(sa));  //SRL

            6'b101001: y<=hi_o;  //MFHI
            6'b101010: y<=lo_o;  //MFLO
            6'b101011: begin  //MTHI
                hilowe<=1'b1;
                hi_i<=a;
                lo_i<=lo_o;
            end
            6'b101100: begin  //MTLO
                hilowe<=1'b1;
                hi_i<=hi_o;
                lo_i<=a;
            end

            6'b000001: begin  //ADD
                y<=addres;
                overflow<=((~a[31]&~b[31]&addres[31])|(a[31]&b[31]&~addres[31]));
            end
            6'b000010: begin  //ADDI
                y<=addres;
                overflow<=((~a[31]&~b[31]&addres[31])|(a[31]&b[31]&~addres[31]));
            end
            6'b000011: y<=addres;  //ADDU
            6'b000100: y<=addres;  //ADDIU
            6'b000101: begin  //SUB
                y<=subres;
                overflow<=((~a[31]&b[31]&subres[31])|(a[31]&~b[31]&~subres[31]));
            end
            6'b000110: y<=subres;  //SUBU
            6'b000111: y<=($signed(a)<$signed(b));  //SLT
            6'b001000: y<=($signed(a)<$signed(b));  //SLTI
            6'b001001: y<=($unsigned(a)<$unsigned(b));  //SLTU
            6'b001010: y<=($unsigned(a)<$unsigned(b));  //SLTIU
            6'b001011: begin  //DIV
                hilowe<=1'b1;
                hi_i<=divres[63:32];
                lo_i<=divres[31:0];
                // hi_i<=$signed(a)%$signed(b);
                // lo_i<=$signed(a)/$signed(b);
            end
            6'b001100: begin  //DIVU
                hilowe<=1'b1;
                hi_i<=divres[63:32];
                lo_i<=divres[31:0];
                // hi_i<=$unsigned(a)%$unsigned(b);
                // lo_i<=$unsigned(a)/$unsigned(b);
            end
            6'b001101: begin  //MULT
                hilowe<=1'b1;
                hi_i<=mulres[63:32];
                lo_i<=mulres[31:0];
            end
            6'b001110: begin  //MULTU
                hilowe<=1'b1;
                hi_i<=mulures[63:32];
                lo_i<=mulures[31:0];
            end

            6'b101111: y<=addres;  //LB
            6'b110000: y<=addres;  //LBU
            6'b110001: y<=addres;  //LH
            6'b110010: y<=addres;  //LHU
            6'b110011: y<=addres;  //LW
            6'b110100: y<=addres;  //SB
            6'b110101: y<=addres;  //SH
            6'b110110: y<=addres;  //SW

            //6'b100101  J无需ALU
            6'b100110: begin  //JAL 
                y<=(pcplus4+32'h4);
                reg31write<=1'b1; 
            end 
            //6'b100111  JR无需ALU
            6'b101000: y<=(pcplus4+32'h4);  //JALR

            //6'b011101:   //BEQ
            //6'b011110:   //BNE
            //6'b011111:   //BGEZ
            //6'b100000:   //BGTZ
            //6'b100001:   //BLEZ
            //6'b100010:   //BLTZ
            6'b100011: begin  //BGEZAL
                y<=(pcplus4+32'h4);
                reg31write<=1'b1;
            end
            6'b100100: begin  //BLTZAL
                y<=(pcplus4+32'h4);
                reg31write<=1'b1;
            end
            //6'b101101  BREAK
            //6'b101110  SYSCALL
            //6'b110111  ERET
            6'b111000: y<=readcp0data;  //MFC0
            6'b111001: y<=b;            //MTC0

            default: y<=0;  //非法指令 
        endcase
    end
endmodule
