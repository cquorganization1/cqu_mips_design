`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/16 10:08:27
// Design Name: 
// Module Name: branch_predict
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


module branch_predict_local (
    input wire clk, rst,
    
    input wire flushD,  
    input wire stallD,

    input wire [31:0] pcF,
    input wire [31:0] pcM,

    input wire branchM,         // M阶段是否是分支指令
    input wire actual_takeM,    // 实际是否跳转

    input wire branchD,        // 译码阶段是否是跳转指令   //改动
    output wire pred_takeD      // 预测是否跳转
);
    wire pred_takeF;
    reg pred_takeF_r;

// 定义参数
    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;

// 
    reg [5:0] BHT [(1<<BHT_DEPTH)-1:0]; //[19:0] 20位，2^20个pht项
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0]; // [9:0] 10位，2^10个
    
    integer i,j;
    wire [(BHT_DEPTH-1):0] pc_hash;
    wire [(PHT_DEPTH-1):0] PHT_index;
    wire [(BHT_DEPTH-1):0] BHT_index;
    wire [(PHT_DEPTH-1):0] BHR_value;

// ---------------------------------------预测逻辑---------------------------------------
    // 对PC哈希
    assign pc_hash = pcF[31:22]^pcF[21:12]^pcF[11:2];
    assign BHT_index = pc_hash;
    assign BHR_value = BHT[BHT_index];
    assign PHT_index = BHR_value ^ BHT_index[5:0];  // 采用异或法

    assign pred_takeF = PHT[PHT_index][1];      // 在取指阶段预测是否会跳转，并经过流水线传递给译码阶段。

        // --------------------------pipeline------------------------------
            always @(posedge clk) begin
                if(rst | flushD) begin
                    pred_takeF_r <= 0;
                end
                else if(~stallD) begin
                    pred_takeF_r <= pred_takeF;
                end
            end
        // --------------------------pipeline------------------------------

// ---------------------------------------预测逻辑---------------------------------------


// ---------------------------------------BHT初始化以及更新---------------------------------------
    wire [(BHT_DEPTH-1):0] pc_hash_M;
    wire [(PHT_DEPTH-1):0] update_PHT_index;
    wire [(BHT_DEPTH-1):0] update_BHT_index;
    wire [(PHT_DEPTH-1):0] update_BHR_value;

    assign pc_hash_M = pcM[31:22]^pcM[21:12]^pcM[11:2];
    assign update_BHT_index = pc_hash_M;   
    assign update_BHR_value = BHT[update_BHT_index];
    assign update_PHT_index = update_BHR_value ^ update_BHT_index[5:0];

    always@(posedge clk) begin
        if(rst) begin
            for(j = 0; j < (1<<BHT_DEPTH); j=j+1) begin
                BHT[j] <= 0;
            end
        end
        else if(branchM) begin
            // 此处应该添加你的更新逻辑的代码
            BHT[update_BHT_index]=update_BHR_value<<1|actual_takeM;
        end
    end
// ---------------------------------------BHT初始化以及更新---------------------------------------


// ---------------------------------------PHT初始化以及更新---------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                PHT[i] <= Weakly_taken;
            end
        end
        else if (branchM) begin
            case(PHT[update_PHT_index])
                // 此处应该添加你的更新逻辑的代码
                Strongly_not_taken: begin
                    if (actual_takeM) begin
                        PHT[update_PHT_index]=Weakly_not_taken;
                    end
                end
                Weakly_not_taken: begin
                    if (actual_takeM) begin
                        PHT[update_PHT_index]=Weakly_taken;
                    end
                    else begin
                        PHT[update_PHT_index]=Strongly_not_taken;
                    end
                end
                Weakly_taken: begin
                    if (actual_takeM) begin
                        PHT[update_PHT_index]=Strongly_taken;
                    end
                    else begin
                        PHT[update_PHT_index]=Weakly_not_taken;
                    end
                end
                Strongly_taken: begin
                    if (!actual_takeM) begin
                        PHT[update_PHT_index]=Weakly_taken;
                    end
                end
            endcase 
        end
    end
// ---------------------------------------PHT初始化以及更新---------------------------------------

    // 译码阶段输出最终的预测结果
    assign pred_takeD = branchD & pred_takeF_r;  


endmodule
