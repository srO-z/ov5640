module ddr3 (
    // ϵͳ�ӿ�-----------------------------------
    input                   clk_200m            ,
    input                   sys_rst_n           ,
    // ��·�ӿ�-----------------------------------
    inout   [15:0]          ddr3_dq             ,
    inout   [ 1:0]          ddr3_dqs_n          ,
    inout   [ 1:0]          ddr3_dqs_p          ,
    output  [13:0]          ddr3_addr           ,
    output  [ 2:0]          ddr3_ba             ,
    output                  ddr3_ras_n          ,
    output                  ddr3_cas_n          ,
    output                  ddr3_we_n           ,
    output                  ddr3_reset_n        ,
    output                  ddr3_ck_p           ,
    output                  ddr3_ck_n           ,
    output                  ddr3_cke            ,
    output                  ddr3_cs_n           ,
    output  [  1:0]         ddr3_dm             ,
    output                  ddr3_odt            ,
    // �ⲿ�ӿ�-----------------------------------
    output                  in_fifo_rd_en       ,
    input   [127:0]         in_fifo_rd_data     ,
    input                   ddr_fifo_rd_en      ,
    output  [ 15:0]         ddr_fifo_rd_data    ,
    input                   ddr_rw              , // ��д����--1: ��--0��д
    input                   ch_switch           , // ͨ���л�--1��д���λ--0��д���λ
    input                   ddr_exc             , // ִ�п���
    input                   frame_start         , // ֡��ʼ��־
    output                  ddr_rd_done         , // һ��ͼ�����ݶ�ȡ���
    output                  ddr_rd_frame_done   , // һ֡����
    output                  ddr_wr_done         , // һ֡ͼ��д�����
    output                  ui_clk              ,
    output                  init_calib_complete 
);
// wire define
// �û��ӿ�-----------------
wire            app_rdy;
wire            app_wdf_rdy;
wire [127:0]    app_rd_data;
wire            app_rd_data_valid;
wire [15:0]     app_wdf_mask;
wire            app_wdf_end;
wire [27:0]     app_addr;
wire [ 2:0]     app_cmd;
wire            app_en;
wire            app_wdf_data;
wire            app_wdf_wren;
wire            ui_clk_sync_rst;
// �ڲ�fifo�ӿ�
wire            out_fifo_wr_en;
wire [127:0]    out_fifo_wr_data;
//              main code
ddr3_rw u_ddr3_rw(
    // �ڲ��û��ӿ�--------------------------------
    .ui_clk                 (ui_clk             ),
    .ui_clk_sync_rst        (ui_clk_sync_rst    ),
    .app_rdy                (app_rdy            ),
    .app_wdf_rdy            (app_wdf_rdy        ),
    .app_rd_data            (app_rd_data        ),
    .app_rd_data_valid      (app_rd_data_valid  ),
    .init_calib_complete    (init_calib_complete),
    .app_wdf_mask           (app_wdf_mask       ),
    .app_wdf_end            (app_wdf_end        ),
    .app_addr               (app_addr           ),
    .app_cmd                (app_cmd            ),
    .app_en                 (app_en             ),
    .app_wdf_data           (app_wdf_data       ),
    .app_wdf_wren           (app_wdf_wren       ),
    .out_fifo_wr_en         (out_fifo_wr_en     ),
    .out_fifo_wr_data       (out_fifo_wr_data   ),
    // �ⲿ�ӿ�-----------------------------------
    .in_fifo_rd_en          (in_fifo_rd_en      ),
    .in_fifo_rd_data        (in_fifo_rd_data    ),
    .ch_switch              (ch_switch          ),
    .ddr_exc                (ddr_exc            ),
    .frame_start            (frame_start        ),
    .ddr_rd_done            (ddr_rd_done        ),
    .ddr_wr_done            (ddr_wr_done        ),
    .ddr_rd_frame_done      (ddr_rd_frame_done  )
);

ddr3_ctrller u_ddr3_ctrller(
    // ϵͳ�ӿ�-----------------------------------
    .clk_200m               (clk_200m           ),
    .sys_rst_n              (sys_rst_n          ),
    // ��·�ӿ�-----------------------------------
    .ddr3_dq                (ddr3_dq            ),
    .ddr3_dqs_n             (ddr3_dqs_n         ),
    .ddr3_dqs_p             (ddr3_dqs_p         ),
    .ddr3_addr              (ddr3_addr          ),
    .ddr3_ba                (ddr3_ba            ),
    .ddr3_ras_n             (ddr3_ras_n         ),
    .ddr3_cas_n             (ddr3_cas_n         ),
    .ddr3_we_n              (ddr3_we_n          ),
    .ddr3_reset_n           (ddr3_reset_n       ),
    .ddr3_ck_p              (ddr3_ck_p          ),
    .ddr3_ck_n              (ddr3_ck_n          ),
    .ddr3_cke               (ddr3_cke           ),
    .ddr3_cs_n              (ddr3_cs_n          ),
    .ddr3_dm                (ddr3_dm            ),
    .ddr3_odt               (ddr3_odt           ),
    // �û��ӿ�-----------------------------------
    .init_calib_complete    (init_calib_complete),
    .app_wdf_mask           (app_wdf_mask       ),
    .app_addr               (app_addr           ),
    .app_cmd                (app_cmd            ),
    .app_en                 (app_en             ),
    .app_wdf_data           (app_wdf_data       ),
    .app_wdf_end            (app_wdf_end        ),
    .app_wdf_wren           (app_wdf_wren       ),
    .app_rdy                (app_rdy            ),
    .app_wdf_rdy            (app_wdf_rdy        ),
    .app_rd_data            (app_rd_data        ),
    .app_rd_data_valid      (app_rd_data_valid  ),
    .ui_clk                 (ui_clk             ),
    .ui_clk_sync_rst        (ui_clk_sync_rst    )
);

// ����ddr�ж�ȡ�����ݴ���fifo
ddr_fifo_128x16_16 u_ddr_fifo (
    .rst        (~sys_rst_n         ),  // input wire rst
    .wr_clk     (ui_clk             ),  // input wire wr_clk
    .rd_clk     (ui_clk             ),  // input wire rd_clk
    .din        (out_fifo_wr_data   ),  // input wire [127 : 0] din
    .wr_en      (out_fifo_wr_en     ),  // input wire wr_en
    .rd_en      (ddr_fifo_rd_en     ),  // input wire rd_en
    .dout       (ddr_fifo_rd_data   ),  // output wire [15 : 0] dout
    .full       (),                     // output wire full
    .empty      (),                     // output wire empty
    .wr_rst_busy(),                     // output wire wr_rst_busy
    .rd_rst_busy()                      // output wire rd_rst_busy
);
endmodule