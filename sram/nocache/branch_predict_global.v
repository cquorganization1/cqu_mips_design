`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/11/11 21:11:46
// Design Name: 
// Module Name: branch_predict2
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


module branch_predict_global (
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
    //assign branchD = 1; //判断译码阶段是否是分支指令

// 定义参数
    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 10;  //由PC 10位和GHR 6位拼接而成
    parameter GHR_DEPTH = 6;

// 
    reg [GHR_DEPTH-1:0] GHR;  //预测阶段使用的GHR
    reg [GHR_DEPTH-1:0] GHR_correct;  //提交阶段正确的GHR
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];
    
    integer i,j;
    wire [(PHT_DEPTH-1):0] pc_hash;
    wire [(PHT_DEPTH-1):0] PHT_index;

// ---------------------------------------预测逻辑---------------------------------------
    // 对PC哈希并与GHR拼接
    assign pc_hash = pcF[31:22]^pcF[21:12]^pcF[11:2];
    assign PHT_index = pc_hash^{GHR,4'b0000};

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
    
    //预测阶段更新GHR
    always @(posedge clk) begin
        if (rst) begin
            GHR=0;
        end
        else begin
            GHR=(GHR<<1)|pred_takeF;
        end
    end
// ---------------------------------------预测逻辑---------------------------------------

    wire [(PHT_DEPTH-1):0] pc_hash_M;
    wire [(PHT_DEPTH-1):0] update_PHT_index;
    
    assign pc_hash_M = pcM[31:22]^pcM[21:12]^pcM[11:2];
    assign update_PHT_index = pc_hash_M^{GHR_correct,4'b0000};

    //通过流水线将预测跳转传到M阶段
    reg pred_takeE,pred_takeM;
    always @(posedge clk) begin
        pred_takeM=pred_takeE;
        pred_takeE=pred_takeF_r;
    end


// ---------------------------------------PHT和GHR_correct初始化以及更新---------------------------------------
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

    always @(posedge clk) begin
        if (rst) begin
            GHR_correct=0;
        end
        else if (branchM) begin
            if (actual_takeM) begin
                GHR_correct=(GHR_correct<<1)|1;
            end
            else begin
                GHR_correct=GHR_correct<<1;
            end
        end
        //将GHR更新为正确的
        if (pred_takeM!=actual_takeM) begin
            GHR=GHR_correct;
        end
    end
// ---------------------------------------PHT和GHR_correct初始化以及更新---------------------------------------

    // 译码阶段输出最终的预测结果
    assign pred_takeD = branchD & pred_takeF_r;  


endmodule

