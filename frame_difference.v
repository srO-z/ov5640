// ����֡�Ҷ�ͼ���������ֵ����0�����ص���ɫ��Ϊffff������Ϊ0
// �����ʽ��16bit���룬��֡frame���ݶ�������
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
wire [16:0] diff_data_w;        // ���λΪ����λ
wire [15:0] abs_diff_data_w;
//              main code
assign diff_data_w = frame1_gray_data - frame2_gray_data;                                           // ����
assign abs_diff_data_w = diff_data_w ? ((diff_data_w[16] ? (~diff_data_w[15:0]) : diff_data_w[15:0]) + 1'b1) : diff_data_w;      // ȡ����ֵ
assign diff_data = frame_data_href ? ((abs_diff_data_w >= 16'd1) ? 16'hffff : 16'd0) : diff_data;   // ���
assign diff_data_vsync = frame_data_vsync;
assign diff_data_href = frame_data_href;
endmodule