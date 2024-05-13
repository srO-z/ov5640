// 将两帧灰度图像作差，绝对值大于0的像素点颜色设为ffff，其他为0
// 输入格式：16bit输入，两帧frame数据对齐输入
module frame_difference (
    input               frame_data_vsync ,
    input               frame_data_href  ,
    input       [15:0]  frame1_gray_data ,
    input       [15:0]  frame2_gray_data ,
    output              diff_data_vsync  ,
    output              diff_data_href   ,
    output      [15:0]  diff_data        
);
// wire define
wire [16:0] diff_data_w;        // 最高位为符号位
wire [15:0] abs_diff_data_w;
//              main code
assign diff_data_w = frame1_gray_data - frame2_gray_data;                                           // 作差
assign abs_diff_data_w = diff_data_w ? ((diff_data_w[16] ? (~diff_data_w[15:0]) : diff_data_w[15:0]) + 1'b1) : diff_data_w;      // 取绝对值
assign diff_data = frame_data_href ? ((abs_diff_data_w >= 16'd1) ? 16'hffff : 16'd0) : diff_data;   // 输出
assign diff_data_vsync = frame_data_vsync;
assign diff_data_href = frame_data_href;
endmodule