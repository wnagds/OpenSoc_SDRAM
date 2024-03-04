`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/07 22:52:07
// Design Name: 
// Module Name: cmd_decode
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


module cmd_decode(
    input           sclk,
    input           reset,
    input           uart_flag,
    input           [7:0]uart_data,
    
    output          wr_trig,
    output          rd_trig,
    output          wfifo_wr_en,
    output          [7:0] wfifo_data
    );
    localparam      REC_NUM_END = 4;
    reg [2:0]       rec_num;
    reg [7:0]       cmd_reg;
    
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            rec_num <= 0;
        else if(uart_flag == 1 && rec_num == 0 && uart_data == 8'haa)
            rec_num <= 0;
        else if(uart_flag == 1 && rec_num >= REC_NUM_END)
            rec_num <=0 ;
        else if(uart_flag == 1)
            rec_num <= rec_num + 1;
    end
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            cmd_reg <= 0;
        else if(uart_flag == 1 && rec_num == 0)
            cmd_reg <= uart_data;
    end
    
    assign wr_trig     = (cmd_reg == 8'h55 && rec_num == REC_NUM_END)? uart_flag : 0;
    assign rd_trig     = uart_flag && (uart_data==8'haa);
    assign wfifo_wr_en = uart_flag && rec_num;
    assign wfifo_data  = uart_data;
endmodule
