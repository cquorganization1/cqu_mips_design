`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/04 20:10:22
// Design Name: 
// Module Name: load
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


module load(
    input wire[31:0] readdata,
    input wire[3:0] memtoreg,
    input wire[1:0] lbshift,
    output reg[31:0] readdatafinal,
    output reg loadexcept
    );

    reg[7:0] temp1;
    reg[15:0] temp2;
    
    always @(*) begin
        case (lbshift)
            2'b00: begin temp1<=readdata[7:0]; temp2<=readdata[15:0]; end
            2'b01: begin temp1<=readdata[15:8]; temp2<=0; end
            2'b10: begin temp1<=readdata[23:16]; temp2<=readdata[31:16]; end
            2'b11: begin temp1<=readdata[31:24]; temp2<=0; end
        endcase
    end

    always @(*) begin
        case (memtoreg)
            4'b1001: readdatafinal<={{24{temp1[7]}},temp1};  //LB
            4'b0001: readdatafinal<={{24{1'b0}},temp1};  //LBU
            4'b1011: readdatafinal<={{16{temp2[15]}},temp2};  //LH
            4'b0011: readdatafinal<={{16{1'b0}},temp2};  //LHU
            4'b1111: readdatafinal<=readdata;  //LW
            default: readdatafinal<=0; 
        endcase
    end
endmodule
