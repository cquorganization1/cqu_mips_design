`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/04 22:42:53
// Design Name: 
// Module Name: save
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


module save(
    input wire[31:0] writedata,
    input wire[3:0] memwrite,
    input wire[1:0] lbshift,
    output reg[31:0] writedatafinal,
    output reg[3:0] memwritefinal
    );

    always @(*) begin
        case (memwrite)
            4'b0001: begin  //SB
                case (lbshift)
                    2'b00: begin writedatafinal<=writedata; memwritefinal<=4'b0001; end
                    2'b01: begin writedatafinal<=writedata<<8; memwritefinal<=4'b0010; end
                    2'b10: begin writedatafinal<=writedata<<16; memwritefinal<=4'b0100; end
                    2'b11: begin writedatafinal<=writedata<<24; memwritefinal<=4'b1000; end
                endcase
            end 
            4'b0011: begin  //SH
                case (lbshift)
                    2'b00: begin writedatafinal<=writedata; memwritefinal<=4'b0011; end
                    2'b10: begin writedatafinal<=writedata<<16; memwritefinal<=4'b1100; end
                    default: begin writedatafinal<=0; memwritefinal<=0; end
                endcase
            end
            4'b1111: begin  //SW
                writedatafinal<=writedata;
                memwritefinal<=4'b1111;
            end
            default: begin writedatafinal<=0; memwritefinal<=0; end
        endcase
    end
endmodule
