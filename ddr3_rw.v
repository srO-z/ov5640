// ��ȡ
// 4:1���ʣ�ddr3�ӿ�ʱ��400MHz���û�ʱ��100MHz
module ddr3_rw #(
    parameter
        BURST_NUM = 8'd80 // 1280 / 16 = 80��
)(
    // ddr�û��ӿ�--------------------------------------------------------------
    input                       ui_clk              , // �û�ʱ��
    input                       ui_clk_sync_rst     , // �û�ͬ����λ���ߵ�ƽ��
    input                       app_rdy             , // �û�����
    input                       app_wdf_rdy         , // �û�д���ݾ���
    input         [127:0]       app_rd_data         , // �û�������
    input                       app_rd_data_valid   , // �û���������Ч
    input                       init_calib_complete , // DDR3 ��ʼ������ź�
    output  reg   [ 15:0]       app_wdf_mask        , // �û�д��������
    output                      app_wdf_end         , // �û�д���ݽ���
    output  reg   [ 27:0]       app_addr            , // �û���ַ
    output  reg   [  2:0]       app_cmd             , // �û������001��д000
    output  reg                 app_en              , // �û�ʹ��
    output  reg   [127:0]       app_wdf_data        , // �û�д����
    output  reg                 app_wdf_wren        , // �û�дʹ��
    // ddr�������fifo�ӿ�-------------------------------------------------------
    output  reg                 in_fifo_rd_en       , // ��ȡʹ�� 
    input         [127:0]       in_fifo_rd_data     , // ��д�������
    output  reg                 out_fifo_wr_en      , // ���ʹ��
    output  reg   [127:0]       out_fifo_wr_data    , // �������
    // ddr��ȡ���������ýӿ�------------------------------------------------------
    // input                       ddr_rw              , // ��д����--1: ��--0��д
    input                       ch_switch           , // ͨ���л�--1��д���λ--0��д���λ
    input                       ddr_exc             , // ִ�п���
    input                       frame_start         , // ֡��ʼ��־
    output  reg                 ddr_rd_done         , // һ��ͼ�����ݶ�ȡ���
    output  reg                 ddr_wr_done         ,  // һ֡ͼ��д�����
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
//---------------- ����߼� ------------------
// ��4:1�����£�����һ��
assign app_wdf_end = app_wdf_wren;  

// ״̬ת���ж�
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

//---------------- ʱ���߼� ------------------
// ��һ�ģ����fifo
always @(posedge ui_clk) begin
    if(ui_clk_sync_rst)
        app_rd_data_d1 <= 128'd0;
    else
        app_rd_data_d1 <= app_rd_data;
end

// ״̬ת��
always @(posedge ui_clk) begin
    if(ui_clk_sync_rst)
        cur_state <= DDR3_INIT;
    else
        cur_state <= next_state;
end

// ״̬���
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
            // д1280bit����һ��ͼ�����ݣ�һ��80��ͻ����80*16 = 1280��
            WRITE:begin                      // 8����ַλΪһ����λ������ĳ��λ���κε�ַ��ʼд128bit���ݣ�һ��ͻ�����ں�8��ʱ�ӣ������Գɹ�д�룬���Ƕ�ȡ��Ҫ�����ͻ����λ�ĵ�һ����ַ���ܳɹ���
                if(app_rdy && app_wdf_rdy)begin
                    cnt <= cnt + 8'd1;
                    case (cnt)
                        8'd0: begin
                            app_en          <= 1'd1;
                            app_cmd         <= 3'd0;
                            app_wdf_wren    <= 1'd1;
                            in_fifo_rd_en   <= 1'd1;
                            app_addr        <= 28'd0;   // ��ʼ��ַ
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
            // ��һ��
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