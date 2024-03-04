`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/26 20:54:51
// Design Name: 
// Module Name: sdram_init
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


module sdram_init(
    sclk,
    reset,
    cmd_reg,
    sdram_addr,
    flag_init_end
    );
    //接口定义
    input sclk;
    input reset;
    output reg [3:0]cmd_reg;
    output reg [11:0]sdram_addr;
    output reg flag_init_end;
    
    //参数定义
    localparam DELAY_200US  =   10000-1;
    localparam PRECHARGE=       4'b0010;
    localparam AUTO_REFRESH=    4'b0001;
    localparam NOP  =           4'b0111;
    localparam MODE_SET=        4'b0000;
    
    
    //内部变量定义
    reg [13:0]cnt_200us;
    reg flag_200us;
    reg [3:0] cnt_cmd;
    
    //计数200us
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            cnt_200us<=0;
        else if(flag_200us==0)
            cnt_200us<=cnt_200us+1'b1;
    end
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            flag_200us<=0;
        else if(cnt_200us>=DELAY_200US)
            flag_200us<=1;
    end
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            cnt_cmd<=0;
        else if(flag_200us == 1 && flag_init_end==0)
            cnt_cmd <=  cnt_cmd +1'b1;
    end
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            flag_init_end<=0;
         else if(cnt_cmd>=10)
            flag_init_end<=1;
    end
    //cmd_reg
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            cmd_reg<=0;
        else if(flag_200us==1)
            case(cnt_cmd)
                0:cmd_reg<=PRECHARGE;
                1:cmd_reg<=AUTO_REFRESH;
                5:cmd_reg<=AUTO_REFRESH;
                9:cmd_reg<=MODE_SET;
                default:cmd_reg<=NOP;
            endcase
    end
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            sdram_addr<=0;
        else if(flag_200us==1)
            case(cnt_cmd)
                0:sdram_addr<=  12'b0100_0000_0000;
                9:sdram_addr<=  12'b0000_0011_0010;
                default:sdram_addr<=  12'b0100_0000_0000;
            endcase
    end
endmodule

