`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/08 10:47:30
// Design Name: 
// Module Name: cmd_decode_tb
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


module cmd_decode_tb( );
    reg sclk;
    reg reset;
    reg rs232_rx;
    wire uart_flag;
    wire [7:0] uart_data; 
    wire wr_trig;
    wire rd_trig;
    wire wfifo_wr_en;
    wire [7:0]wfifo_data;
    uart_rx uart_rx_inst(
    .sclk               (sclk),
    .reset              (reset),
    .rs232_rx           (rs232_rx),
    
    .rx_data            (uart_data),
    .po_flag            (uart_flag)
    );
    cmd_decode cmd_decode_inst(
        .sclk                  (sclk),
        .reset                 (reset),
        .uart_flag             (uart_flag),
        .uart_data             (uart_data),
        
        .wr_trig               (wr_trig),
        .rd_trig               (rd_trig),
        .wfifo_wr_en           (wfifo_wr_en),
        .wfifo_data            (wfifo_data)
        );
        initial begin
            sclk = 1;
            reset = 0;
            #201;
            reset = 1;
            tx_byte;
            $stop;
        end
        always #10 sclk = ~sclk;
        task tx_byte();
            repeat(2)begin
                tx_bit(8'h55);  //–¥√¸¡Ó
                #3000;
                tx_bit(8'h12);
                #3000;
                tx_bit(8'h34);
                #3000;
                tx_bit(8'h56);
                #3000;
                tx_bit(8'h78);
                #3000;
                tx_bit(8'haa);  //∂¡√¸¡Ó
                #3000;
            end
        endtask
            
            task tx_bit;
            input [7:0]data;
            begin
               rs232_rx=1;
               #20;
               rs232_rx=0;
               #8680;
               
               rs232_rx=data[0];
               #8680;
               rs232_rx=data[1];
               #8680;
               rs232_rx=data[2];
               #8680;   
               rs232_rx=data[3];
              #8680;
              rs232_rx=data[4];
              #8680;
              rs232_rx=data[5];
              #8680;      
              rs232_rx=data[6];
              #8680;
              rs232_rx=data[7];
              #8680;      
              
              rs232_rx=1;
              #8680;
            end
        endtask
endmodule
