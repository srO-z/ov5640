//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           img_data_pkt
// Last modified Date:  2020/2/18 9:20:14
// Last Version:        V1.0
// Descriptions:        图像封装模块(添加帧头)    
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/2/18 9:20:14
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module img_data_pkt_ref(
    input                 rst_n             ,   //复位信号，低电平有效
    input                 cam_pclk          ,   //像素时钟
    input                 img_vsync         ,   //帧同步信号
    input                 img_data_en       ,   //数据有效使能信号
    input        [7 :0]   img_data          ,   //有效数据 
    input                 transfer_flag     ,   //图像开始传输标志,1:开始传输 0:停止传输
    input                 eth_tx_clk        ,   //以太网发送时钟
    input                 udp_tx_req        ,   //udp发送数据请求信号
    input                 udp_tx_done       ,   //udp发送数据完成信号                               
    output  reg           udp_tx_start_en   ,   //udp开始发送信号
    output       [7 :0]   udp_tx_data       ,   //udp发送的数据
    output  reg  [15:0]   udp_tx_byte_num      //udp单包发送的有效字节数
    );    
    
//parameter define
parameter  CMOS_H_PIXEL = 16'd640;  //图像水平方向分辨率
parameter  CMOS_V_PIXEL = 16'd480;  //图像垂直方向分辨率
//图像帧头,用于标志一帧数据的开始
parameter  IMG_FRAME_HEAD = {32'hf0_5a_a5_0f};

reg             img_vsync_d0    ;  //帧有效信号打拍
reg             img_vsync_d1    ;  //帧有效信号打拍
reg             img_vsync_d2    ;  //帧有效信号打拍

reg             img_data_en_d0  ;  //数据有效使能信号
reg    [7 :0]   img_data_d0     ;  //有效图像数据打拍
reg	   [3 :0]	head_cnt		;  //帧头计数器	
reg				head_flag		;  //帧头标志位
reg             wr_fifo_en      ;  //写fifo使能
reg    [7 :0]   wr_fifo_data    ;  //写fifo数据

reg             img_vsync_txc_d0;  //以太网发送时钟域下,帧有效信号打拍
reg             img_vsync_txc_d1;  //以太网发送时钟域下,帧有效信号打拍
reg             img_vsync_txc_d2;  //以太网发送时钟域下,帧有效信号打拍
reg             tx_busy_flag    ;  //发送忙信号标志
reg		[1:0]	bit_sel			;                                

//wire define                   
wire            pos_vsync       ;  //帧有效信号上升沿
wire            neg_vsync       ;  //帧有效信号下降沿
wire            neg_vsynt_txc   ;  //以太网发送时钟域下,帧有效信号下降沿
wire   [10:0]   fifo_rdusedw    ;  //当前FIFO缓存的个数

//*****************************************************
//**                    main code
//*****************************************************

//信号采沿
assign neg_vsync = img_vsync_d2 & (~img_vsync_d1);
assign pos_vsync = ~img_vsync_d2 & img_vsync_d1;
assign neg_vsynt_txc = ~img_vsync_txc_d2 & img_vsync_txc_d1;

//对img_vsync信号延时三个时钟周期,用于采沿
always @(posedge cam_pclk or negedge rst_n) begin
    if(!rst_n) begin
        img_vsync_d0 <= 1'b0;
        img_vsync_d1 <= 1'b0;
		img_vsync_d2 <= 1'b0;
    end
    else begin
        img_vsync_d0 <= img_vsync;
        img_vsync_d1 <= img_vsync_d0;
		img_vsync_d2 <= img_vsync_d1;
    end
end

//帧头计数器
always @(posedge cam_pclk or negedge rst_n) begin
    if(!rst_n)
		head_cnt <= 4'd0;
	else if(neg_vsync)
		head_cnt <= 4'd0;
	else if(head_cnt == 4'd8)
		head_cnt <= head_cnt;
	else
		head_cnt <= head_cnt + 4'd1;
end
		
//帧头标志位		
always @(posedge cam_pclk or negedge rst_n) begin
    if(!rst_n)
		head_flag <= 1'd0;
	else if(neg_vsync)
		head_flag <= 1'd1;
	else if(head_cnt == 4'd7)
		head_flag <= 1'd0;
	else ;
end
		
//同步数据有效信号和有效数据
always @(posedge cam_pclk or negedge rst_n) begin
    if(!rst_n) begin
		img_data_en_d0 <= 1'd0;
		img_data_d0 <= 8'd0;
	end
	else begin
		img_data_en_d0 <= img_data_en;
		img_data_d0 <= img_data;
	end
end	


//将帧头和图像数据写入FIFO
always @(posedge cam_pclk or negedge rst_n) begin
    if(!rst_n) begin
        wr_fifo_en <= 1'b0;
        wr_fifo_data <= 8'd0;
    end
    else begin
		wr_fifo_en <= 1'b1;
        if(head_flag) begin
            wr_fifo_en <= 1'b1;
			if(head_cnt == 4'd0)
				wr_fifo_data <= IMG_FRAME_HEAD[31:24];               //帧头
			else if(head_cnt == 4'd1)
				wr_fifo_data <= IMG_FRAME_HEAD[23:16];               //帧头
			else if(head_cnt == 4'd2)
				wr_fifo_data <= IMG_FRAME_HEAD[15: 8];               //帧头
			else if(head_cnt == 4'd3)
				wr_fifo_data <= IMG_FRAME_HEAD[ 7: 0];               //帧头
			else if(head_cnt == 4'd4)
				wr_fifo_data <= CMOS_H_PIXEL[15: 8];               	 //水平方向分辨率
			else if(head_cnt == 4'd5)
				wr_fifo_data <= CMOS_H_PIXEL[ 7: 0];               	 //水平方向分辨率
			else if(head_cnt == 4'd6)
				wr_fifo_data <= CMOS_V_PIXEL[15: 8];               	 //垂直方向分辨率
			else if(head_cnt == 4'd7)
				wr_fifo_data <= CMOS_V_PIXEL[ 7: 0];               	 //垂直方向分辨率
			else ;	
        end
        else if(img_data_en_d0) begin
            wr_fifo_en <= 1'b1;
			wr_fifo_data <= img_data_d0;
        end
        else begin
            wr_fifo_en <= 1'b0;
            wr_fifo_data <= 8'd0;       
        end
    end
end

//以太网发送时钟域下,对img_vsync信号延时三个时钟周期,用于采沿
always @(posedge eth_tx_clk or negedge rst_n) begin
    if(!rst_n) begin
        img_vsync_txc_d0 <= 1'b0;
        img_vsync_txc_d1 <= 1'b0;
		img_vsync_txc_d2 <= 1'b0;
    end
    else begin
        img_vsync_txc_d0 <= img_vsync;
        img_vsync_txc_d1 <= img_vsync_txc_d0;
		img_vsync_txc_d2 <= img_vsync_txc_d1;
    end
end

//控制以太网发送的字节数
always @(posedge eth_tx_clk or negedge rst_n) begin
    if(!rst_n)
        udp_tx_byte_num <= 1'b0;
    else if(neg_vsynt_txc)
        udp_tx_byte_num <= {CMOS_H_PIXEL,1'b0} + 16'd8;
    else if(udp_tx_done)    
        udp_tx_byte_num <= {CMOS_H_PIXEL,1'b0};
end

//控制以太网发送开始信号
always @(posedge eth_tx_clk or negedge rst_n) begin
    if(!rst_n) begin
        udp_tx_start_en <= 1'b0;
        tx_busy_flag <= 1'b0;
    end
    //上位机未发送"开始"命令时,以太网不发送图像数据
    else if(transfer_flag == 1'b0) begin
        udp_tx_start_en <= 1'b0;
        tx_busy_flag <= 1'b0;        
    end
    else begin
        udp_tx_start_en <= 1'b0;
        //当FIFO中的个数满足需要发送的字节数时
        if(tx_busy_flag == 1'b0 && fifo_rdusedw >= udp_tx_byte_num[15:0]) begin
            udp_tx_start_en <= 1'b1;                     //开始控制发送一包数据
            tx_busy_flag <= 1'b1;
        end
        else if(udp_tx_done || neg_vsynt_txc) 
            tx_busy_flag <= 1'b0;
    end
end

// //异步FIFO
fifo_generator_0 async_fifo_2048x8b_inst (
  .rst(pos_vsync | (~transfer_flag)),       // input wire rst
  .wr_clk(cam_pclk),                		// input wire wr_clk
  .rd_clk(eth_tx_clk),                		// input wire rd_clk
  .din(wr_fifo_data),                      	// input wire [7 : 0] din
  .wr_en(wr_fifo_en),                  		// input wire wr_en
  .rd_en(udp_tx_req),                  		// input wire rd_en
  .dout(udp_tx_data),                    	// output wire [7 : 0] dout
  .full(),                    				// output wire full
  .empty(),                  				// output wire empty
  .rd_data_count(fifo_rdusedw),  			// output wire [10 : 0] rd_data_count
  .wr_rst_busy(),      						// output wire wr_rst_busy
  .rd_rst_busy()      						// output wire rd_rst_busy
);   

/*
    ila测试 udp_tx_clk 时钟域
    测试信号：
        pclk时钟域：(要在udp时钟域打两拍再用)
        vsync           1 bit
        href            1 bit 
        cam_data        8 bit
        wr_fifo_en      1 bit
        wr_fifo_data    8 bit

        udp时钟域：
        rd_fifo_en      1 bit
        rd_fifo_data    8 bit
        rd_data_count   11 bit
*/

reg vsync_d2_t1, vsync_d2_t2;
reg href_d2_t1, href_d2_t2;
reg [7:0] cam_data_d2_t1, cam_data_d2_t2;
reg wr_fifo_en_d2_t1, wr_fifo_en_d2_t2;
reg [7:0] wr_fifo_data_d2_t1, wr_fifo_data_d2_t2;

always @(posedge eth_tx_clk or negedge rst_n) begin
    if(~rst_n)begin
        vsync_d2_t1 <= 1'd0;
        vsync_d2_t2 <= 1'd0;
        href_d2_t1 <= 1'd0;
        href_d2_t2 <= 1'd0;
        cam_data_d2_t1 <= 8'd0;
        cam_data_d2_t2 <= 8'd0;
        wr_fifo_en_d2_t1 <= 1'd0;
        wr_fifo_en_d2_t2 <= 1'd0;
        wr_fifo_data_d2_t1 <= 1'd0;
        wr_fifo_data_d2_t2 <= 1'd0;
    end
    else begin
        vsync_d2_t1 <= img_vsync_d0;
        vsync_d2_t2 <= vsync_d2_t1;

        href_d2_t1 <= img_data_en_d0;
        href_d2_t2 <= href_d2_t1;

        cam_data_d2_t1 <= img_data_d0;
        cam_data_d2_t2 <= cam_data_d2_t1;

        wr_fifo_en_d2_t1 <= wr_fifo_en;
        wr_fifo_en_d2_t2 <= wr_fifo_en_d2_t1;

        wr_fifo_data_d2_t1 <= wr_fifo_data;
        wr_fifo_data_d2_t2 <= wr_fifo_data_d2_t1;
    end
end
ila_0 ins_ila (
	.clk(eth_tx_clk), // input wire clk

	.probe0(vsync_d2_t2), // input wire [0:0]  probe0  
	.probe1(href_d2_t2), // input wire [0:0]  probe1 
	.probe2(cam_data_d2_t2), // input wire [7:0]  probe2 
	.probe3(wr_fifo_en_d2_t2), // input wire [0:0]  probe3 
	.probe4(wr_fifo_data_d2_t2), // input wire [7:0]  probe4 
	.probe5(udp_tx_req), // input wire [0:0]  probe5 
	.probe6(udp_tx_data), // input wire [7:0]  probe6 
	.probe7(fifo_rdusedw) // input wire [10:0]  probe7
);
endmodule