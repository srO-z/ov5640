// 存取
// 4:1速率，ddr3接口时钟400MHz，用户时钟100MHz
module ddr3_rw #(
    parameter
        BURST_NUM = 8'd80 // 1280 / 16 = 80次
)(
    // ddr用户接口--------------------------------------------------------------
    input                       ui_clk              , // 用户时钟
    input                       ui_clk_sync_rst     , // 用户同步复位（高电平）
    input                       app_rdy             , // 用户就绪
    input                       app_wdf_rdy         , // 用户写数据就绪
    input         [127:0]       app_rd_data         , // 用户读数据
    input                       app_rd_data_valid   , // 用户读数据有效
    input                       init_calib_complete , // DDR3 初始化完成信号
    output  reg   [ 15:0]       app_wdf_mask        , // 用户写数据掩码
    output                      app_wdf_end         , // 用户写数据结束
    output  reg   [ 27:0]       app_addr            , // 用户地址
    output  reg   [  2:0]       app_cmd             , // 用户命令，读001，写000
    output  reg                 app_en              , // 用户使能
    output  reg   [127:0]       app_wdf_data        , // 用户写数据
    output  reg                 app_wdf_wren        , // 用户写使能
    // ddr输入输出fifo接口-------------------------------------------------------
    output  reg                 in_fifo_rd_en       , // 读取使能 
    input         [127:0]       in_fifo_rd_data     , // 待写入的数据
    output  reg                 out_fifo_wr_en      , // 输出使能
    output  reg   [127:0]       out_fifo_wr_data    , // 输出数据
    // ddr存取启动和配置接口------------------------------------------------------
    // input                       ddr_rw              , // 读写控制--1: 读--0：写
    input                       ch_switch           , // 通道切换--1：写入高位--0：写入低位
    input                       ddr_exc             , // 执行控制
    input                       frame_start         , // 帧开始标志
    output  reg                 ddr_rd_done         , // 一行图像数据读取完毕
    output  reg                 ddr_wr_done         ,  // 一帧图像写入完毕
    output  reg                 ddr_rd_frame_done   
);
// parameter define
localparam
    DDR3_INIT = 5'b00001,
    IDLE      = 5'b00010,
    WRITE     = 5'b00100,
    READ      = 5'b01000,
    OUTPUT    = 5'b10000;
    
// reg define
reg [  4:0] cur_state, next_state;
reg         skip;
reg [  7:0] cnt;
reg [ 15:0] read_data;
reg [  7:0] burst_cnt;
reg [  8:0] wr_row_cnt, rd_row_cnt;
reg [127:0] app_rd_data_d1;
reg         ddr_rw;
//              main code
//---------------- 组合逻辑 ------------------
// 在4:1速率下，这俩一致
assign app_wdf_end = app_wdf_wren;  

// 状态转换判断
always @(*)begin
    case (cur_state)
        DDR3_INIT: next_state = init_calib_complete ? IDLE                    : DDR3_INIT;
        IDLE     : next_state = ddr_exc             ? (ddr_rw ? READ : WRITE) : IDLE     ;
        WRITE    : next_state = skip                ? IDLE                    : WRITE    ;
        READ     : next_state = skip                ? OUTPUT                  : READ     ;
        OUTPUT   : next_state = skip                ? IDLE                    : OUTPUT   ;
        default  : next_state = DDR3_INIT;
    endcase
end

//---------------- 时序逻辑 ------------------
// 打一拍，存进fifo
always @(posedge ui_clk) begin
    if(ui_clk_sync_rst)
        app_rd_data_d1 <= 128'd0;
    else
        app_rd_data_d1 <= app_rd_data;
end

// 状态转换
always @(posedge ui_clk) begin
    if(ui_clk_sync_rst)
        cur_state <= DDR3_INIT;
    else
        cur_state <= next_state;
end

// 状态输出
always @(posedge ui_clk) begin
    if(ui_clk_sync_rst)begin
        app_addr        <= 28'd0;
        app_cmd         <= 3'd0;
        app_en          <= 1'd0;
        app_wdf_data    <= 128'd0;
        app_wdf_wren    <= 1'd0;
        cnt             <= 8'd0;
        skip            <= 1'd0;
        burst_cnt       <= 8'd0;
        in_fifo_rd_en   <= 1'd0;
        ddr_wr_done     <= 1'd0;
        ddr_rd_done     <= 1'd0;
        out_fifo_wr_en  <= 1'd0;
        wr_row_cnt      <= 9'd0;
        rd_row_cnt      <= 9'd0;
    end
    else begin
        skip <= 1'd0;
        ddr_wr_done <= 1'd0;
        ddr_rd_done <= 1'd0;
        case (next_state)
            DDR3_INIT: begin
                app_addr        <= 28'd0;
                app_cmd         <= 3'd0;
                app_en          <= 1'd0;
                app_wdf_data    <= 128'd0;
                app_wdf_wren    <= 1'd0;
                cnt             <= 8'd0;
                skip            <= 1'd0;
                burst_cnt       <= 8'd0;
                in_fifo_rd_en   <= 1'd0;
                ddr_wr_done     <= 1'd0;
                ddr_rd_done     <= 1'd0;
                out_fifo_wr_en  <= 1'd0;
                app_wdf_mask    <= 16'd0;
                ddr_rw          <= 1'd0;
            end
            IDLE: begin
                app_wdf_mask        <= ddr_rw ? 16'd0 : (ch_switch ? 16'h00ff : 16'hff00);
                app_addr            <= frame_start ? 28'd0 : app_addr;
                app_cmd             <= 3'd0;
                app_en              <= 1'd0;
                app_wdf_data        <= 128'd0;
                app_wdf_wren        <= 1'd0;
                cnt                 <= 8'd0;
                burst_cnt           <= 8'd0;
                in_fifo_rd_en       <= 1'd0;
                wr_row_cnt          <= (wr_row_cnt == 9'd479) ? 9'd0 : wr_row_cnt;
                ddr_wr_done         <= (wr_row_cnt == 9'd479) ? 1'd1 : 1'd0;
                rd_row_cnt          <= (rd_row_cnt == 9'd479) ? 9'd0 : rd_row_cnt;
                ddr_rd_frame_done   <= (rd_row_cnt == 9'd479) ? 1'd1 : 1'd0;
                ddr_rd_done         <= 1'd0;
                ddr_rw              <= ddr_wr_done ? 1'd1 : ddr_rw;
                ddr_rw              <= ddr_rd_frame_done ? 1'd0 : ddr_rw;
            end
            // 写1280bit，即一行图像数据，一共80个突发（80*16 = 1280）
            WRITE:begin                      // 8个地址位为一个单位，可以某单位的任何地址开始写128bit数据，一个突发周期后（8个时钟），可以成功写入，但是读取需要读这个突发单位的第一个地址才能成功读
                if(app_rdy && app_wdf_rdy)begin
                    cnt <= cnt + 8'd1;
                    case (cnt)
                        8'd0: begin
                            app_en          <= 1'd1;
                            app_cmd         <= 3'd0;
                            app_wdf_wren    <= 1'd1;
                            in_fifo_rd_en   <= 1'd1;
                            app_addr        <= 28'd0;   // 初始地址
                        end
                        8'd1: begin
                            in_fifo_rd_en   <= 1'd0;
                            app_wdf_data    <= in_fifo_rd_data;
                        end
                        8'd8: begin
                            in_fifo_rd_en  <= 1'd1;
                            app_en <= (burst_cnt == (BURST_NUM - 8'd1)) ? 1'd0 : app_en;
                        end 
                        8'd9: begin
                            in_fifo_rd_en   <= 1'd0;
                            app_wdf_data    <= in_fifo_rd_data;
                            app_addr        <= app_addr + 28'd8;
                            burst_cnt       <= burst_cnt + 8'd1;
                            if(burst_cnt == (BURST_NUM - 8'd1))begin
                                app_wdf_wren    <= 1'd0;
                                cnt             <= 8'd0;
                                wr_row_cnt      <= wr_row_cnt + 9'd1;
                                skip            <= 1'd1;
                                ddr_wr_done     <= 1'd1;
                            end 
                            else
                                cnt <= 8'd2;
                        end
                    endcase  
                end
                else ;
            end
            // 读一行
            READ: begin
                if(app_rdy)begin
                    cnt <= cnt + 8'd1;
                    if(cnt == 8'd0)begin
                        app_cmd <= 3'd1;
                        app_en <= 1'd1;
                        app_addr <= 28'd0;
                    end
                    else if(cnt == (BURST_NUM -8'd1))begin
                        app_en <= 1'd0;
                        cnt <= 8'd0;
                        skip <= 1'd1;
                    end
                    else ;

                    if(cnt < BURST_NUM && cnt > 8'd0)
                        app_addr <= app_addr + 28'd8;
                    else ;
                end
            end
            OUTPUT: begin
                if(app_rd_data_valid)begin
                    burst_cnt <= burst_cnt + 8'd1;
                    if(burst_cnt == 8'd0)
                        out_fifo_wr_en <= 1'd1;
                    else if(burst_cnt == 8'd80)begin
                        rd_row_cnt <= rd_row_cnt + 9'd1;
                        skip <= 1'd1;
                        ddr_rd_done <= 1'd1;
                        out_fifo_wr_en <= 1'd0;
                    end
                    else ;
                    
                    if((burst_cnt <= 8'd80) && (burst_cnt >= 8'd1))
                        out_fifo_wr_data <= app_rd_data_d1;
                    else 
                        out_fifo_wr_data <= 128'd0;
                end
            end
        endcase
    end
end
endmodule