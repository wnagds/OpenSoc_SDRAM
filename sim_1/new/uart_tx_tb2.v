`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/26 16:45:38
// Design Name: 
// Module Name: uart_tx_tb
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


module uart_tx_tb2(

    );
    reg sclk;
    reg reset;
    reg [7:0]tx_data;
    reg tx_trig;
    wire RS232_tx;
    
    uart_tx ut(
    .sclk(sclk),
    .reset(reset),
    .tx_data(tx_data),
    .tx_trig(tx_trig),
    
    .RS232_tx(RS232_tx)
    );
    initial sclk=1;
    always #10 sclk=!sclk;
    initial begin
        reset=0;
        tx_trig=0;
        #201;
        reset=1'b1;
        tx_data=8'hc3;
        tx_trig=1'b1;
        #20;
        tx_trig=0;
        #2_000_000;
        tx_data=8'ha4;
        #20;
        tx_trig=1'b1;
        #20;
        tx_trig=0;
        #200000;
        $stop;
    end
    
endmodule
