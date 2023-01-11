`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/10 13:20:11
// Design Name: 
// Module Name: branchdecide
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


module branchdecide(
    input wire[5:0] label,
    input wire[31:0] branchsrca,branchsrcb,
    output reg needbranch
    );

    always @(*)begin
        case (label)
            6'b011101: needbranch<=(branchsrca==branchsrcb);  //BEQ
            6'b011110: needbranch<=(branchsrca!=branchsrcb);  //BNE
            6'b011111: needbranch<=($signed(branchsrca)>=0);  //BGEZ
            6'b100000: needbranch<=($signed(branchsrca)>0);   //BGTZ
            6'b100001: needbranch<=($signed(branchsrca)<=0);  //BLEZ
            6'b100010: needbranch<=($signed(branchsrca)<0);   //BLTZ
            6'b100011: needbranch<=($signed(branchsrca)>=0);  //BGEZAL
            6'b100100: needbranch<=($signed(branchsrca)<0);   //BLTZAL
            default: needbranch<=1'b0; 
        endcase
    end
endmodule
