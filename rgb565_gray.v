// rgb565ת�Ҷ�ͼ�񣬲���䵽rgb565ԭͨ������ԭʱ����������ӳ���6��ʱ������
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
reg [ 5:0] href_d6, vsync_d6;       // һ��6���ӳ٣���ʼ��8bitת16bit����2�ģ��м䴦����3�ģ����16bitת8bit����1��

// wire define
wire [7:0] r0, g0, b0;
wire [15:0] gray_data_b16;
wire vsync_d5, href_d5;
//              main code
// rgb565תrgb888
assign r0 = {rgb_data[15:11], rgb_data[13:11]};
assign g0 = {rgb_data[10: 5], rgb_data[ 6: 5]};
assign b0 = {rgb_data[ 4: 0], rgb_data[ 2: 0]};

// �Ҷ�ͼ���������rgb565��ͨ��
assign gray_data_b16 = {y2[7:3], y2[7:2], y2[7:3]};

// 8bit��cam_dataת16bit����������
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

// �˷����ָ�ֵ 

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

// �ӷ����ָ�ֵ���Ӽ�������������3����
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

// YCbCr��ʽ���
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

// 16bit�Ҷ�ͼ��ת8bit
always @(posedge cam_pclk or negedge rst_n) begin // �ӳ�5�ĵõ�gray_vsync��gray_href
    if(~rst_n)begin
        vsync_d6 <= 5'd0;
        href_d6 <= 5'd0;
    end
    else begin
        vsync_d6 <= {vsync_d6[4:0], cam_vsync};
        href_d6 <= {href_d6[4:0], cam_href};
    end
end 
assign gray_vsync = vsync_d6[5]; // �ӳ�6��
assign gray_href = href_d6[5];
assign vsync_d5 = vsync_d6[4];   // �ӳ�5��
assign href_d5 = href_d6[4];

always @(posedge cam_pclk or negedge rst_n) begin// 16bit��gray_data_b16ת8bit��gray_data
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