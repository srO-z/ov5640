module sccb_cfg #(
    parameter
        CMOS_H_PIXEL  = 16'd640  ,
        CMOS_V_PIXEL  = 16'd480  ,
        TOTAL_H_PIXEL = 16'd1856 ,
        TOTAL_V_PIXEL = 16'd984   
)(
    input               dri_clk         , // 200kHz
    inout               rst_n           ,
    input               sccb_done       ,
    input       [7:0]   sccb_rd_data    ,
    output reg  [23:0]  sccb_wr_data    ,
    output reg          sccb_exc        ,
    output reg          sccb_rw         ,
    output reg          sccb_init_done       
);
// reg define
reg [15:0] wait_30ms_cnt;
reg [15:0] wait_10ms_cnt;
reg [7:0] cnt;
reg wait_10ms_start_flag;
reg wait_10ms_start_flag_d1;
// wire define
wire wait_10ms_start_flag_neg;

//                  main code
assign wait_10ms_start_flag_neg = ~wait_10ms_start_flag & wait_10ms_start_flag_d1;
always @(posedge dri_clk or negedge rst_n)begin
    if(~rst_n)
        wait_10ms_start_flag_d1 <= 1'd0;
    else
        wait_10ms_start_flag_d1 <= wait_10ms_start_flag;
end

// 30ms初始等待
always @(posedge dri_clk or negedge rst_n)begin
    if(~rst_n)begin
        wait_30ms_cnt <= 16'd0;
    end
    else if(wait_30ms_cnt == 16'd6000)
            wait_30ms_cnt <= wait_30ms_cnt;
    else
        wait_30ms_cnt <= wait_30ms_cnt + 16'd1; 

end

// 10ms软复位等待
always @(posedge dri_clk or negedge rst_n)begin
    if(~rst_n)begin
        wait_10ms_cnt <= 16'd0;
    end
    else if(wait_10ms_cnt == 16'd2000)
            wait_10ms_cnt <= wait_10ms_cnt;
    else if(wait_10ms_start_flag)
        wait_10ms_cnt <= wait_10ms_cnt + 16'd1; 
    else ;
end

// 写寄存器地址和数据
always @(posedge dri_clk or negedge rst_n)begin
    if(~rst_n)begin
        sccb_rw <= 1'd1;
        sccb_exc <= 1'd0;
        sccb_init_done <= 1'd0;
        wait_10ms_start_flag <= 1'd0;
        cnt <= 8'd0;
    end
    else begin
        if((sccb_wr_data == {16'h3008,8'h82}) && sccb_done)      // 软复位寄存器写完后开始等待10ms
            wait_10ms_start_flag <= 1'd1;
        else ;

        if(wait_10ms_cnt == 16'd1998)begin                       // 软复位等待完毕
            cnt <= 8'd4;
            wait_10ms_start_flag <= 1'd0;
        end
        else ;

        // 其他寄存器写入
        if(wait_30ms_cnt == 16'd5999)           // 执行软复位
            sccb_exc <= 1'd1;
        else if(wait_10ms_start_flag_neg)       // 执行cnt为4的寄存器，此时wait_10ms_cnt为1999，sccb_wr_data的值已经是第四项寄存器的值
            sccb_exc <= 1'd1;
        else if((8'd4 <= cnt) && (cnt <= 8'd246) && sccb_done)begin
            sccb_exc <= 1'd1;
            cnt <= cnt + 8'd1;
        end
        else begin
            sccb_exc <= 1'd0;
        end

        // ov5640初始化完毕
        if(cnt == 8'd247)
            sccb_init_done <= 1'd1;
        else ;
    end
end

always @(posedge dri_clk or negedge rst_n)begin
    if(~rst_n)begin
        sccb_wr_data <= 24'd0;
    end
    else begin
        // 执行软复位
        if(wait_30ms_cnt == 16'd5999)                      
            sccb_wr_data <= {16'h3008,8'h82};
        else ;

        case (cnt)
            //先读OV5640 ID
            // 8'd0  : sccb_wr_data <= {16'h300a,8'h0};  //
            8'd0  : ;  //
            8'd1  : sccb_wr_data <= {16'h300b,8'h0};  //
            8'd2  : sccb_wr_data <= {16'h3008,8'h82}; //Bit[7]:复位 Bit[6]:电源休眠
            8'd3  : sccb_wr_data <= {16'h3008,8'h42}; //正常工作模式
            8'd4  : sccb_wr_data <= {16'h3103,8'h03}; //Bit[1]:1 PLL Clock
            //引脚输入/输出控制 FREX/VSYNC/HREF/PCLK/D[9:6]
            8'd5  : sccb_wr_data <= {8'h30,8'h17,8'hff};
            //引脚输入/输出控制 D[5:0]/GPIO1/GPIO0 
            8'd6  : sccb_wr_data <= {16'h3018,8'hff};
            8'd7  : sccb_wr_data <= {16'h3037,8'h13}; //PLL分频控制
            8'd8  : sccb_wr_data <= {16'h3108,8'h01}; //系统根分频器
            8'd9  : sccb_wr_data <= {16'h3630,8'h36};
            8'd10 : sccb_wr_data <= {16'h3631,8'h0e};
            8'd11 : sccb_wr_data <= {16'h3632,8'he2};
            8'd12 : sccb_wr_data <= {16'h3633,8'h12};
            8'd13 : sccb_wr_data <= {16'h3621,8'he0};
            8'd14 : sccb_wr_data <= {16'h3704,8'ha0};
            8'd15 : sccb_wr_data <= {16'h3703,8'h5a};
            8'd16 : sccb_wr_data <= {16'h3715,8'h78};
            8'd17 : sccb_wr_data <= {16'h3717,8'h01};
            8'd18 : sccb_wr_data <= {16'h370b,8'h60};
            8'd19 : sccb_wr_data <= {16'h3705,8'h1a};
            8'd20 : sccb_wr_data <= {16'h3905,8'h02};
            8'd21 : sccb_wr_data <= {16'h3906,8'h10};
            8'd22 : sccb_wr_data <= {16'h3901,8'h0a};
            8'd23 : sccb_wr_data <= {16'h3731,8'h12};
            8'd24 : sccb_wr_data <= {16'h3600,8'h08}; //VCM控制,用于自动聚焦
            8'd25 : sccb_wr_data <= {16'h3601,8'h33}; //VCM控制,用于自动聚焦
            8'd26 : sccb_wr_data <= {16'h302d,8'h60}; //系统控制
            8'd27 : sccb_wr_data <= {16'h3620,8'h52};
            8'd28 : sccb_wr_data <= {16'h371b,8'h20};
            8'd29 : sccb_wr_data <= {16'h471c,8'h50};
            8'd30 : sccb_wr_data <= {16'h3a13,8'h43}; //AEC(自动曝光控制)
            8'd31 : sccb_wr_data <= {16'h3a18,8'h00}; //AEC 增益上限
            8'd32 : sccb_wr_data <= {16'h3a19,8'hf8}; //AEC 增益上限
            8'd33 : sccb_wr_data <= {16'h3635,8'h13};
            8'd34 : sccb_wr_data <= {16'h3636,8'h03};
            8'd35 : sccb_wr_data <= {16'h3634,8'h40};
            8'd36 : sccb_wr_data <= {16'h3622,8'h01};
            8'd37 : sccb_wr_data <= {16'h3c01,8'h34};
            8'd38 : sccb_wr_data <= {16'h3c04,8'h28};
            8'd39 : sccb_wr_data <= {16'h3c05,8'h98};
            8'd40 : sccb_wr_data <= {16'h3c06,8'h00}; //light meter 1 阈值[15:8]
            8'd41 : sccb_wr_data <= {16'h3c07,8'h08}; //light meter 1 阈值[7:0]
            8'd42 : sccb_wr_data <= {16'h3c08,8'h00}; //light meter 2 阈值[15:8]
            8'd43 : sccb_wr_data <= {16'h3c09,8'h1c}; //light meter 2 阈值[7:0]
            8'd44 : sccb_wr_data <= {16'h3c0a,8'h9c}; //sample number[15:8]
            8'd45 : sccb_wr_data <= {16'h3c0b,8'h40}; //sample number[7:0]
            8'd46 : sccb_wr_data <= {16'h3810,8'h00}; //Timing Hoffset[11:8]
            8'd47 : sccb_wr_data <= {16'h3811,8'h10}; //Timing Hoffset[7:0]
            8'd48 : sccb_wr_data <= {16'h3812,8'h00}; //Timing Voffset[10:8]
            8'd49 : sccb_wr_data <= {16'h3708,8'h64};
            8'd50 : sccb_wr_data <= {16'h4001,8'h02}; //BLC(黑电平校准)补偿起始行号
            8'd51 : sccb_wr_data <= {16'h4005,8'h1a}; //BLC(黑电平校准)补偿始终更新
            8'd52 : sccb_wr_data <= {16'h3000,8'h00}; //系统块复位控制
            8'd53 : sccb_wr_data <= {16'h3004,8'hff}; //时钟使能控制
            8'd54 : sccb_wr_data <= {16'h4300,8'h61}; //格式控制 RGB565
            8'd55 : sccb_wr_data <= {16'h501f,8'h01}; //ISP RGB
            8'd56 : sccb_wr_data <= {16'h440e,8'h00};
            8'd57 : sccb_wr_data <= {16'h5000,8'ha7}; //ISP控制
            8'd58 : sccb_wr_data <= {16'h3a0f,8'h30}; //AEC控制;stable range in high
            8'd59 : sccb_wr_data <= {16'h3a10,8'h28}; //AEC控制;stable range in low
            8'd60 : sccb_wr_data <= {16'h3a1b,8'h30}; //AEC控制;stable range out high
            8'd61 : sccb_wr_data <= {16'h3a1e,8'h26}; //AEC控制;stable range out low
            8'd62 : sccb_wr_data <= {16'h3a11,8'h60}; //AEC控制; fast zone high
            8'd63 : sccb_wr_data <= {16'h3a1f,8'h14}; //AEC控制; fast zone low
            //LENC(镜头校正)控制 16'h5800~16'h583d
            8'd64 : sccb_wr_data <= {16'h5800,8'h23}; 
            8'd65 : sccb_wr_data <= {16'h5801,8'h14};
            8'd66 : sccb_wr_data <= {16'h5802,8'h0f};
            8'd67 : sccb_wr_data <= {16'h5803,8'h0f};
            8'd68 : sccb_wr_data <= {16'h5804,8'h12};
            8'd69 : sccb_wr_data <= {16'h5805,8'h26};
            8'd70 : sccb_wr_data <= {16'h5806,8'h0c};
            8'd71 : sccb_wr_data <= {16'h5807,8'h08};
            8'd72 : sccb_wr_data <= {16'h5808,8'h05};
            8'd73 : sccb_wr_data <= {16'h5809,8'h05};
            8'd74 : sccb_wr_data <= {16'h580a,8'h08};
            8'd75 : sccb_wr_data <= {16'h580b,8'h0d};
            8'd76 : sccb_wr_data <= {16'h580c,8'h08};
            8'd77 : sccb_wr_data <= {16'h580d,8'h03};
            8'd78 : sccb_wr_data <= {16'h580e,8'h00};
            8'd79 : sccb_wr_data <= {16'h580f,8'h00};
            8'd80 : sccb_wr_data <= {16'h5810,8'h03};
            8'd81 : sccb_wr_data <= {16'h5811,8'h09};
            8'd82 : sccb_wr_data <= {16'h5812,8'h07};
            8'd83 : sccb_wr_data <= {16'h5813,8'h03};
            8'd84 : sccb_wr_data <= {16'h5814,8'h00};
            8'd85 : sccb_wr_data <= {16'h5815,8'h01};
            8'd86 : sccb_wr_data <= {16'h5816,8'h03};
            8'd87 : sccb_wr_data <= {16'h5817,8'h08};
            8'd88 : sccb_wr_data <= {16'h5818,8'h0d};
            8'd89 : sccb_wr_data <= {16'h5819,8'h08};
            8'd90 : sccb_wr_data <= {16'h581a,8'h05};
            8'd91 : sccb_wr_data <= {16'h581b,8'h06};
            8'd92 : sccb_wr_data <= {16'h581c,8'h08};
            8'd93 : sccb_wr_data <= {16'h581d,8'h0e};
            8'd94 : sccb_wr_data <= {16'h581e,8'h29};
            8'd95 : sccb_wr_data <= {16'h581f,8'h17};
            8'd96 : sccb_wr_data <= {16'h5820,8'h11};
            8'd97 : sccb_wr_data <= {16'h5821,8'h11};
            8'd98 : sccb_wr_data <= {16'h5822,8'h15};
            8'd99 : sccb_wr_data <= {16'h5823,8'h28};
            8'd100: sccb_wr_data <= {16'h5824,8'h46};
            8'd101: sccb_wr_data <= {16'h5825,8'h26};
            8'd102: sccb_wr_data <= {16'h5826,8'h08};
            8'd103: sccb_wr_data <= {16'h5827,8'h26};
            8'd104: sccb_wr_data <= {16'h5828,8'h64};
            8'd105: sccb_wr_data <= {16'h5829,8'h26};
            8'd106: sccb_wr_data <= {16'h582a,8'h24};
            8'd107: sccb_wr_data <= {16'h582b,8'h22};
            8'd108: sccb_wr_data <= {16'h582c,8'h24};
            8'd109: sccb_wr_data <= {16'h582d,8'h24};
            8'd110: sccb_wr_data <= {16'h582e,8'h06};
            8'd111: sccb_wr_data <= {16'h582f,8'h22};
            8'd112: sccb_wr_data <= {16'h5830,8'h40};
            8'd113: sccb_wr_data <= {16'h5831,8'h42};
            8'd114: sccb_wr_data <= {16'h5832,8'h24};
            8'd115: sccb_wr_data <= {16'h5833,8'h26};
            8'd116: sccb_wr_data <= {16'h5834,8'h24};
            8'd117: sccb_wr_data <= {16'h5835,8'h22};
            8'd118: sccb_wr_data <= {16'h5836,8'h22};
            8'd119: sccb_wr_data <= {16'h5837,8'h26};
            8'd120: sccb_wr_data <= {16'h5838,8'h44};
            8'd121: sccb_wr_data <= {16'h5839,8'h24};
            8'd122: sccb_wr_data <= {16'h583a,8'h26};
            8'd123: sccb_wr_data <= {16'h583b,8'h28};
            8'd124: sccb_wr_data <= {16'h583c,8'h42};
            8'd125: sccb_wr_data <= {16'h583d,8'hce};
            //AWB(自动白平衡控制) 16'h5180~16'h519e
            8'd126: sccb_wr_data <= {16'h5180,8'hff};
            8'd127: sccb_wr_data <= {16'h5181,8'hf2};
            8'd128: sccb_wr_data <= {16'h5182,8'h00};
            8'd129: sccb_wr_data <= {16'h5183,8'h14};
            8'd130: sccb_wr_data <= {16'h5184,8'h25};
            8'd131: sccb_wr_data <= {16'h5185,8'h24};
            8'd132: sccb_wr_data <= {16'h5186,8'h09};
            8'd133: sccb_wr_data <= {16'h5187,8'h09};
            8'd134: sccb_wr_data <= {16'h5188,8'h09};
            8'd135: sccb_wr_data <= {16'h5189,8'h75};
            8'd136: sccb_wr_data <= {16'h518a,8'h54};
            8'd137: sccb_wr_data <= {16'h518b,8'he0};
            8'd138: sccb_wr_data <= {16'h518c,8'hb2};
            8'd139: sccb_wr_data <= {16'h518d,8'h42};
            8'd140: sccb_wr_data <= {16'h518e,8'h3d};
            8'd141: sccb_wr_data <= {16'h518f,8'h56};
            8'd142: sccb_wr_data <= {16'h5190,8'h46};
            8'd143: sccb_wr_data <= {16'h5191,8'hf8};
            8'd144: sccb_wr_data <= {16'h5192,8'h04};
            8'd145: sccb_wr_data <= {16'h5193,8'h70};
            8'd146: sccb_wr_data <= {16'h5194,8'hf0};
            8'd147: sccb_wr_data <= {16'h5195,8'hf0};
            8'd148: sccb_wr_data <= {16'h5196,8'h03};
            8'd149: sccb_wr_data <= {16'h5197,8'h01};
            8'd150: sccb_wr_data <= {16'h5198,8'h04};
            8'd151: sccb_wr_data <= {16'h5199,8'h12};
            8'd152: sccb_wr_data <= {16'h519a,8'h04};
            8'd153: sccb_wr_data <= {16'h519b,8'h00};
            8'd154: sccb_wr_data <= {16'h519c,8'h06};
            8'd155: sccb_wr_data <= {16'h519d,8'h82};
            8'd156: sccb_wr_data <= {16'h519e,8'h38};
            //Gamma(伽马)控制 16'h5480~16'h5490
            8'd157: sccb_wr_data <= {16'h5480,8'h01}; 
            8'd158: sccb_wr_data <= {16'h5481,8'h08};
            8'd159: sccb_wr_data <= {16'h5482,8'h14};
            8'd160: sccb_wr_data <= {16'h5483,8'h28};
            8'd161: sccb_wr_data <= {16'h5484,8'h51};
            8'd162: sccb_wr_data <= {16'h5485,8'h65};
            8'd163: sccb_wr_data <= {16'h5486,8'h71};
            8'd164: sccb_wr_data <= {16'h5487,8'h7d};
            8'd165: sccb_wr_data <= {16'h5488,8'h87};
            8'd166: sccb_wr_data <= {16'h5489,8'h91};
            8'd167: sccb_wr_data <= {16'h548a,8'h9a};
            8'd168: sccb_wr_data <= {16'h548b,8'haa};
            8'd169: sccb_wr_data <= {16'h548c,8'hb8};
            8'd170: sccb_wr_data <= {16'h548d,8'hcd};
            8'd171: sccb_wr_data <= {16'h548e,8'hdd};
            8'd172: sccb_wr_data <= {16'h548f,8'hea};
            8'd173: sccb_wr_data <= {16'h5490,8'h1d};
            //CMX(彩色矩阵控制) 16'h5381~16'h538b
            8'd174: sccb_wr_data <= {16'h5381,8'h1e};
            8'd175: sccb_wr_data <= {16'h5382,8'h5b};
            8'd176: sccb_wr_data <= {16'h5383,8'h08};
            8'd177: sccb_wr_data <= {16'h5384,8'h0a};
            8'd178: sccb_wr_data <= {16'h5385,8'h7e};
            8'd179: sccb_wr_data <= {16'h5386,8'h88};
            8'd180: sccb_wr_data <= {16'h5387,8'h7c};
            8'd181: sccb_wr_data <= {16'h5388,8'h6c};
            8'd182: sccb_wr_data <= {16'h5389,8'h10};
            8'd183: sccb_wr_data <= {16'h538a,8'h01};
            8'd184: sccb_wr_data <= {16'h538b,8'h98};
            //SDE(特殊数码效果)控制 16'h5580~16'h558b
            8'd185: sccb_wr_data <= {16'h5580,8'h06};
            8'd186: sccb_wr_data <= {16'h5583,8'h40};
            8'd187: sccb_wr_data <= {16'h5584,8'h10};
            8'd188: sccb_wr_data <= {16'h5589,8'h10};
            8'd189: sccb_wr_data <= {16'h558a,8'h00};
            8'd190: sccb_wr_data <= {16'h558b,8'hf8};
            8'd191: sccb_wr_data <= {16'h501d,8'h40}; //ISP MISC
            //CIP(颜色插值)控制 (16'h5300~16'h530c)
            8'd192: sccb_wr_data <= {16'h5300,8'h08};
            8'd193: sccb_wr_data <= {16'h5301,8'h30};
            8'd194: sccb_wr_data <= {16'h5302,8'h10};
            8'd195: sccb_wr_data <= {16'h5303,8'h00};
            8'd196: sccb_wr_data <= {16'h5304,8'h08};
            8'd197: sccb_wr_data <= {16'h5305,8'h30};
            8'd198: sccb_wr_data <= {16'h5306,8'h08};
            8'd199: sccb_wr_data <= {16'h5307,8'h16};
            8'd200: sccb_wr_data <= {16'h5309,8'h08};
            8'd201: sccb_wr_data <= {16'h530a,8'h30};
            8'd202: sccb_wr_data <= {16'h530b,8'h04};
            8'd203: sccb_wr_data <= {16'h530c,8'h06};
            8'd204: sccb_wr_data <= {16'h5025,8'h00};
            //系统时钟分频 Bit[7:4]:系统时钟分频 input clock =24Mhz, PCLK = 48Mhz
            8'd205: sccb_wr_data <= {16'h3035,8'h11}; 
            8'd206: sccb_wr_data <= {16'h3036,8'h3c}; //PLL倍频
            8'd207: sccb_wr_data <= {16'h3c07,8'h08};
            //时序控制 16'h3800~16'h3821
            8'd208: sccb_wr_data <= {16'h3820,8'h41};
            8'd209: sccb_wr_data <= {16'h3821,8'h01};
            8'd210: sccb_wr_data <= {16'h3814,8'h31};
            8'd211: sccb_wr_data <= {16'h3815,8'h31};
            8'd212: sccb_wr_data <= {16'h3800,8'h00};
            8'd213: sccb_wr_data <= {16'h3801,8'h00};
            8'd214: sccb_wr_data <= {16'h3802,8'h00};
            8'd215: sccb_wr_data <= {16'h3803,8'h04};
            8'd216: sccb_wr_data <= {16'h3804,8'h0a};
            8'd217: sccb_wr_data <= {16'h3805,8'h3f};
            8'd218: sccb_wr_data <= {16'h3806,8'h07};
            8'd219: sccb_wr_data <= {16'h3807,8'h9b};
            //设置输出像素个数
            //DVP 输出水平像素点数高4位
            8'd220: sccb_wr_data <= {16'h3808,{4'd0,CMOS_H_PIXEL[11:8]}};
            //DVP 输出水平像素点数低8位
            8'd221: sccb_wr_data <= {16'h3809,CMOS_H_PIXEL[7:0]};
            //DVP 输出垂直像素点数高3位
            8'd222: sccb_wr_data <= {16'h380a,{5'd0,CMOS_V_PIXEL[10:8]}};
            //DVP 输出垂直像素点数低8位
            8'd223: sccb_wr_data <= {16'h380b,CMOS_V_PIXEL[7:0]};
            //水平总像素大小高5位
            8'd224: sccb_wr_data <= {16'h380c,{3'd0,TOTAL_H_PIXEL[12:8]}};
            //水平总像素大小低8位 
            8'd225: sccb_wr_data <= {16'h380d,TOTAL_H_PIXEL[7:0]};
            //垂直总像素大小高5位 
            8'd226: sccb_wr_data <= {16'h380e,{3'd0,TOTAL_V_PIXEL[12:8]}};
            //垂直总像素大小低8位     
            8'd227: sccb_wr_data <= {16'h380f,TOTAL_V_PIXEL[7:0]};
            8'd228: sccb_wr_data <= {16'h3813,8'h06};
            8'd229: sccb_wr_data <= {16'h3618,8'h00};
            8'd230: sccb_wr_data <= {16'h3612,8'h29};
            8'd231: sccb_wr_data <= {16'h3709,8'h52};
            8'd232: sccb_wr_data <= {16'h370c,8'h03};
            8'd233: sccb_wr_data <= {16'h3a02,8'h17}; //60Hz max exposure
            8'd234: sccb_wr_data <= {16'h3a03,8'h10}; //60Hz max exposure
            8'd235: sccb_wr_data <= {16'h3a14,8'h17}; //50Hz max exposure
            8'd236: sccb_wr_data <= {16'h3a15,8'h10}; //50Hz max exposure
            8'd237: sccb_wr_data <= {16'h4004,8'h02}; //BLC(背光) 2 lines
            8'd238: sccb_wr_data <= {16'h4713,8'h03}; //JPEG mode 3
            8'd239: sccb_wr_data <= {16'h4407,8'h04}; //量化标度
            8'd240: sccb_wr_data <= {16'h460c,8'h22};     
            8'd241: sccb_wr_data <= {16'h4837,8'h22}; //DVP CLK divider
            8'd242: sccb_wr_data <= {16'h3824,8'h02}; //DVP CLK divider
            8'd243: sccb_wr_data <= {16'h5001,8'ha3}; //ISP 控制
            8'd244: sccb_wr_data <= {16'h3b07,8'h0a}; //帧曝光模式  
            //彩条测试使能 
            8'd245: sccb_wr_data <= {16'h503d,8'h00}; //8'h00:正常模式 8'h80:彩条显示
            //测试闪光灯功能
            8'd246: sccb_wr_data <= {16'h3016,8'h02};
            8'd247: sccb_wr_data <= {16'h301c,8'h02};
            8'd248: sccb_wr_data <= {16'h3019,8'h02}; //打开闪光灯
            8'd249: sccb_wr_data <= {16'h3019,8'h00}; //关闭闪光灯
            //只读存储器,防止在case中没有列举的情况，之前的寄存器被重复改写
            // default : sccb_wr_data <= {16'h300a,8'h00}; //器件ID高8位
        endcase
    end
end

            
endmodule