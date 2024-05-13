// rgb565转灰度图像，并填充到rgb565原通道，以原时序输出，但延迟了6个时钟周期
module rbg565_gray (
    input             cam_pclk  ,
    input             rst_n     ,
    input             cam_vsync ,
    input             cam_href  ,
    input      [7:0]  cam_data  ,
    output            gray_vsync, 
    output            gray_href ,
    output reg [7:0]  gray_data 
);
// reg define
reg [15:0] r1, g1, b1, r2, g2, b2, r3, g3, b3;
reg [15:0] y1, cb1, cr1;
reg [ 7:0] y2, cb2, cr2;
reg [15:0] rgb_data;
reg [ 7:0] cnt_for_b16, cnt_for_b8, rgb_data_r;
reg [ 5:0] href_d6, vsync_d6;       // 一共6拍延迟，开始的8bit转16bit花费2拍，中间处理花费3拍，最后16bit转8bit花费1拍

// wire define
wire [7:0] r0, g0, b0;
wire [15:0] gray_data_b16;
wire vsync_d5, href_d5;
//              main code
// rgb565转rgb888
assign r0 = {rgb_data[15:11], rgb_data[13:11]};
assign g0 = {rgb_data[10: 5], rgb_data[ 6: 5]};
assign b0 = {rgb_data[ 4: 0], rgb_data[ 2: 0]};

// 灰度图像输出给到rgb565的通道
assign gray_data_b16 = {y2[7:3], y2[7:2], y2[7:3]};

// 8bit的cam_data转16bit的像素数据
always @(posedge cam_pclk or negedge rst_n) begin
    if(~rst_n)
        cnt_for_b16 <= 8'd0;
    else if(cam_href)
        cnt_for_b16 <= cnt_for_b16 + 8'd1;
    else
        cnt_for_b16 <= 8'd0;
        
end
always @(posedge cam_pclk or negedge rst_n) begin
    if(~rst_n)begin
        rgb_data <= 16'd0;
        rgb_data_r <= 16'd0;
    end
    else if(cnt_for_b16[0] == 1'd0)
        rgb_data_r <= cam_data;
    else
        rgb_data <= {rgb_data_r, cam_data};
end

// 乘法部分赋值 

always @(posedge cam_pclk or negedge rst_n) begin
    if(~rst_n)begin
        {r1, g1, b1} <= {3{16'd0}};
        // {r2, g2, b2} <= {3{16'd0}};
        // {r3, g3, b3} <= {3{16'd0}};
    end
    else begin
        {r1, g1, b1} <= {r0 *  77, g0 * 150, b0 *  29};
        // {r2, g2, b2} <= {r0 *  43, g0 *  85, b0 * 128};
        // {r3, g3, b3} <= {r0 * 128, g0 * 107, b0 *  21};
    end
end

// 加法部分赋值（加减法个数不超过3个）
always @(posedge cam_pclk or negedge rst_n) begin
    if(~rst_n)begin
         y1 <= 16'd0;
        // cb1 <= 16'd0;
        // cr1 <= 16'd0;
    end
    else begin
         y1 <= r1 + g1 + b1;
        // cb1 <= b2 - g2 - r2 + 16'd32768;
        // cr1 <= r3 - g3 - b3 + 16'd32768;
    end
end

// YCbCr格式输出
always @(posedge cam_pclk or negedge rst_n) begin
    if(~rst_n)begin
         y2 <= 8'd0;
        // cb2 <= 8'd0;
        // cr2 <= 8'd0;
    end
    else begin
         y2 <= y1 [15:8];
        // cb2 <= cb1[15:8];
        // cr2 <= cr1[15:8];
    end
end

// 16bit灰度图像转8bit
always @(posedge cam_pclk or negedge rst_n) begin // 延迟5拍得到gray_vsync和gray_href
    if(~rst_n)begin
        vsync_d6 <= 5'd0;
        href_d6 <= 5'd0;
    end
    else begin
        vsync_d6 <= {vsync_d6[4:0], cam_vsync};
        href_d6 <= {href_d6[4:0], cam_href};
    end
end 
assign gray_vsync = vsync_d6[5]; // 延迟6拍
assign gray_href = href_d6[5];
assign vsync_d5 = vsync_d6[4];   // 延迟5拍
assign href_d5 = href_d6[4];

always @(posedge cam_pclk or negedge rst_n) begin// 16bit的gray_data_b16转8bit的gray_data
    if(~rst_n)
        cnt_for_b8 <= 8'd0;
    else if(vsync_d6)
        cnt_for_b8 <= cnt_for_b8 + 8'd1;
    else
        cnt_for_b8 <= 8'd0;
        
end
always @(posedge cam_pclk or negedge rst_n) begin
    if(~rst_n)begin
        gray_data <= 8'd0;
    end
    else if(cnt_for_b8[0] == 1'd0)
        gray_data <= gray_data_b16[15:8];
    else
        gray_data <= gray_data_b16[ 7:0];
end
endmodule