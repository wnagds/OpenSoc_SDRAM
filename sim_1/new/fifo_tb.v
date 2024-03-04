`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/09 09:35:13
// Design Name: 
// Module Name: fifo_tb
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


module fifo_tb(

    );
    reg sclk;
    reg wr_en;
    reg rd_en;
    reg [7:0]wr_data;
    wire [8:0]rd_data;
    wire empty;
    wire full;
    fifo_16x8 wfifo_inst
    (
        .clk        (sclk),
        .wr_en      (wr_en),
        .din        (wr_data),
        .rd_en      (rd_en),
        .dout       (rd_data),
        .full       (full),
        .empty      (empty)
    );
    initial sclk = 1;
    always #10 sclk = ~sclk;
    initial begin
        wr_en = 0;
        rd_en = 0;
        #201;
        wr({8'h12,8'h34,8'h56,8'h78});
        #20;
        rd_en = 1;
        #200;
        $stop;
    end
    task wr;
    input [31:0] idata;
    begin
    wr_data = idata[31:24];
    wr_en = 1;
    #20;
    wr_data = idata[23:16];
    #20;
    wr_data = idata[23:16];
    #20;
    wr_data = idata[15:8];
    #20;
    wr_data = idata[7:0];
    #20;
    wr_en = 0;
    end
    endtask
endmodule
