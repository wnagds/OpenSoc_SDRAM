`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/27 19:22:21
// Design Name: 
// Module Name: sdram_aref
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


module sdram_aref(
    //系统信号
    sclk,
    reset,
    //与仲裁机的接口
    ref_en,
    ref_req,
    flag_ref_end,
    //其他接口
    aref_cmd,
    sdram_addr,
    flag_init_end
    );
    input sclk;
    input reset;
    input flag_init_end;
    input ref_en;
    
    output reg ref_req;
    output reg flag_ref_end;
    //刷新命令寄存器
    output reg [3:0]aref_cmd;
    output reg [11:0] sdram_addr;
    localparam      DELAY_15US=750-1;
    localparam      BANK=12'b0100_0000_0000;//对所有bank进行刷新
    localparam      CMD_AREF=4'b0001;
    localparam      CMD_NOP=4'b0111;
    localparam      CMD_PRE=4'b0010;
    localparam      CMD_END=4'd10;
    reg [3:0] cmd_cnt;
    reg [9:0] ref_cnt;
    reg flag_ref;
    //刷新计数器
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            ref_cnt<=0;
        else if(ref_cnt == DELAY_15US)
            ref_cnt<=0;
        else if(flag_init_end==1'b1)
            ref_cnt<=ref_cnt+1'b1;
        else ref_cnt<=ref_cnt;
    end
    //刷新请求
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            ref_req<=0;
        else if(ref_en==1) ref_req<=0;
        else if(ref_cnt >= DELAY_15US)
            ref_req<=1;
    end
    //刷新标志位
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            flag_ref<=0;
        else if(cmd_cnt >=CMD_END)
            flag_ref<=0;
        else if(ref_en==1'b1)
            flag_ref<=1'b1;
    end
    //刷新中、、、、、、、、、
    //命令计数器
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            cmd_cnt<=0;
        else if(!flag_ref)
            cmd_cnt<=0;
        else cmd_cnt<=cmd_cnt+1;
    end
    //输出命令
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            aref_cmd    <=  CMD_NOP;
        else case(cmd_cnt)
            1-1: 
                if(flag_ref == 1)
                    aref_cmd    <=  CMD_PRE;       
                else
                    aref_cmd    <=  CMD_NOP;
            
            2-1:    aref_cmd    <=  CMD_AREF;
            6-1:    aref_cmd    <=  CMD_AREF;
            default:aref_cmd<=    CMD_NOP;
        endcase
    end
   always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            flag_ref_end<=0;
        else if(cmd_cnt>=CMD_END)
            flag_ref_end<=1;
        else flag_ref_end<=0;
    end
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            sdram_addr <= 0;
        else case(cmd_cnt)
            1-1:
                sdram_addr <=   BANK;
            default:
                sdram_addr <=   0;
        endcase
    end
   
    
endmodule
