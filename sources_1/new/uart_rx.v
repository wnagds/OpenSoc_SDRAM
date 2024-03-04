`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/25 20:57:57
// Design Name: 
// Module Name: uart_rx
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


module uart_rx(
    input sclk,
    input reset,
    input rs232_rx,
    output reg [7:0] rx_data,
    output reg po_flag 
    );
    localparam BAUD_END     	=1_000_000_000/115200/20-1;
	localparam BAUD_M 			=BAUD_END/2-1;
	localparam BIT_END  		=10;
	
    reg [7:0]outdata_r;
	reg rx_r1;
	reg rx_r2;
	reg rx_r3;
	reg rx_flag;
	reg [12:0] baud_cnt;
	reg bit_flag;
	reg [3:0] bit_cnt;
	wire rx_neg;
    assign rx_neg=({rx_r2,rx_r1}==2'b10);
    //慢两拍
	always@(posedge sclk)
	begin
		rx_r1<=rs232_rx;
		rx_r2<=rx_r1;
		rx_r3<=rx_r2;
	end
	//接受开始
	always@(posedge sclk or negedge reset)
	begin
		if(!reset)
			rx_flag <= 0;
		else if(rx_neg)
			rx_flag<=1;
		else if(bit_cnt==10 && baud_cnt>= BAUD_END)
			rx_flag<=0;	
		
	end
	//波特率计数器
	always@(posedge sclk or negedge reset)
	begin
	   if(!reset)
	       baud_cnt<=0;
	    else if(baud_cnt>=BAUD_END)
	       baud_cnt<=0;
	    else if(rx_flag)
	       baud_cnt<=baud_cnt+1;
	    else baud_cnt<=0;
	end
	//位末脉冲
	always@(posedge sclk or negedge reset)
	begin
		if(!reset)
			bit_flag<=0;
		else if(baud_cnt==BAUD_M)
		begin
			bit_flag <=1;
		end
		else bit_flag<=0;
	end
	always@(posedge sclk or negedge reset)
	begin
		if(!reset)
			bit_cnt<=0;
		else if(baud_cnt>=BAUD_END && bit_cnt==10)  //到第9位
			bit_cnt<=0;
		else if(bit_flag==1)
			bit_cnt	<=bit_cnt +1;
	end
	always@(posedge sclk or negedge reset)
	begin
		if(!reset)
			outdata_r <= 0;
		else if(!rx_flag)
		    outdata_r <= 0;
		else if(bit_flag ==1 && bit_cnt >= 1&& bit_cnt <=8)
			outdata_r <= {rx_r2,outdata_r[7:1]};  
	end
	
	always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            rx_data <= 0;
        else if(bit_cnt==10&&baud_cnt>=BAUD_END)
            rx_data<=outdata_r;
    end
	always@(posedge sclk or negedge reset)
	begin
		if(!reset)
			po_flag <= 0;
		else if(bit_cnt ==10 &&baud_cnt>=BAUD_END)
			po_flag	<=1;
		else po_flag<=0;
	end
endmodule
