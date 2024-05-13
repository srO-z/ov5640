module img_data_pkt #(
parameter  
    IMG_FRAME_HEAD = {32'hf0_5a_a5_0f},
    CMOS_H_PIXEL = 16'd640,  // image horizontal direction pixels number
    CMOS_V_PIXEL = 16'd480   // image vertical direction pixels number
    
)(
    input               clk               ,   // 48MHz
    input               rst_n             ,
    input       [7:0]   img_data_i        ,
    input               img_href_i        ,   // image data valid enable
    input               img_vsync_i       ,   // vertical sync signal
    input               init_done         ,   // 初始化结束后开始发送数据
    input               ddr_init_done     ,   
    // ddr3
    input               ui_clk            ,   // 100MHz
    input               ddr_fifo_rd_en    ,
    output      [63:0]  ddr_fifo_rd_data  ,
    output reg          ddr_exc           ,   // 每执行一次，存一行
    output reg          frame_start       ,   // 用于刷新sdram的存储地址和掩码 
    output reg          led               
);

// reg define
// cam 时钟域-------------------------------------
reg [7:0] img_data, img_data_i_d1, img_data_i_d2;
reg img_href, img_href_i_d1, img_href_i_d2;
reg img_vsync, img_vsync_i_d1, img_vsync_i_d2;
reg fifo_wr_en;
reg img_vsync_d1, img_href_d1;
reg [7:0] fifo_wr_data;
reg data_send_en;
// sdram 时钟域-----------------------------------
reg neg_img_vsync_sdram;
reg neg_img_href_sdram;

// wire define
wire pos_img_vsync, neg_img_href;
wire [10:0] rd_data_count;

//              main code
// 先打拍，防止亚稳态
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n)begin
        img_data_i_d1  <= 8'd0;
        img_data_i_d2  <= 8'd0;
        img_href_i_d1  <= 1'd0;
        img_href_i_d2  <= 1'd0;
        img_vsync_i_d1 <= 1'd0;
        img_vsync_i_d2 <= 1'd0;
    end
    else begin
        img_data_i_d1 <= img_data_i;
        img_data_i_d2 <= img_data_i_d1;
        img_data <= img_data_i_d2;

        img_href_i_d1 <= img_href_i;
        img_href_i_d2 <= img_href_i_d1;
        img_href <= img_href_i_d2;

        img_vsync_i_d1 <= img_vsync_i;
        img_vsync_i_d2 <= img_vsync_i_d1;
        img_vsync <= img_vsync_i_d2;
    end
end

// 标志第一行帧
assign neg_img_vsync = (~img_vsync) & img_vsync_d1; 
assign neg_img_href = (~img_href) & img_href_d1; 

always @(posedge clk or negedge rst_n) begin 
    if(~rst_n)begin
        img_vsync_d1 <= 1'd0;
        img_href_d1 <= 1'd0;
    end
    else begin
        img_vsync_d1 <= img_vsync;
        img_href_d1 <= img_href;
    end
end

// 等待initialization结束
always @(posedge clk or negedge rst_n) begin 
    if(~rst_n)
        data_send_en <= 1'd0;
    else
        data_send_en <= (init_done && ddr_init_done) ? 1'd1 : data_send_en;
end

// 写数据
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        fifo_wr_en <= 1'd0;
        fifo_wr_data <= 8'd0;
    end
    else begin
        if(data_send_en)begin
            if(img_href)begin                
                fifo_wr_en <= 1'd1;
                fifo_wr_data <= img_data;
            end
            else begin
                fifo_wr_en <= 1'd0;
                fifo_wr_data <= 8'd0;
            end   
        end
        else ;
    end
end

fifo_cam_data_2048x8 u_fifo_cam_data_8x2048_64 (
    .rst((~rst_n) | pos_img_vsync),   // input wire rst
    .wr_clk(clk),                     // input wire wr_clk
    .rd_clk(ui_clk),                  // input wire rd_clk
    .din(fifo_wr_data),               // input wire [7 : 0] din
    .wr_en(fifo_wr_en),               // input wire wr_en
    .rd_en(ddr_fifo_rd_en),           // input wire rd_en
    .dout(ddr_fifo_rd_data),          // output wire [63 : 0] dout
    .full(),                          // output wire full
    .empty(),                         // output wire empty
    .rd_data_count(rd_data_count),    // output wire [10 : 0] rd_data_count
    .wr_rst_busy(),                   // output wire wr_rst_busy
    .rd_rst_busy()                    // output wire rd_rst_busy
);

// sdram时钟域 100MHz -------------------------------------------------------

// 对cam时钟域的信号进行打拍
always @(posedge ui_clk or negedge rst_n) begin 
    if(~rst_n)begin
        neg_img_vsync_sdram <= 1'd0;
        neg_img_href_sdram <= 1'd0;
    end
    else begin
        neg_img_vsync_sdram <= neg_img_vsync;
        neg_img_href_sdram <= neg_img_href;
    end
end

// 输出第一帧标志
always @(posedge ui_clk or negedge rst_n) begin 
    if(~rst_n)
        frame_start <= 1'd0;
    else
        frame_start <= neg_img_vsync_sdram ? 1'd1 : 1'd0;
end

// 输出ddr执行信号
always @(posedge ui_clk or negedge rst_n) begin 
    if(~rst_n)
        ddr_exc <= 1'd0;
    else
        ddr_exc <= neg_img_href_sdram ? 1'd1 : 1'd0;
end
endmodule