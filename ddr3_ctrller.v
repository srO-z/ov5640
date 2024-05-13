// 输入200MHz，内部时钟400MHz，用户端100MHz
module ddr3_ctrller (
    // system ---------------------------------------------------------------------
    input                   clk_200m            , // 200Mhz
    input                   sys_rst_n           , // 复位，低电平有效
    // ddr3 电路接口 ---------------------------------------------------------------
    inout   [15:0]          ddr3_dq             , // ddr3 数据线
    inout   [ 1:0]          ddr3_dqs_n          , // ddr3 数据选通负信号
    inout   [ 1:0]          ddr3_dqs_p          , // ddr3 数据选通正信号
    output  [13:0]          ddr3_addr           , // ddr3 地址线
    output  [ 2:0]          ddr3_ba             , // ddr3 Bank地址
    output                  ddr3_ras_n          , // ddr3 行地址选通信号，低电平有效
    output                  ddr3_cas_n          , // ddr3 列地址选通信号，低电平有效
    output                  ddr3_we_n           , // ddr3 写使能信号，低电平有效
    output                  ddr3_reset_n        , // ddr3 复位信号，低电平有效
    output                  ddr3_ck_p           , // ddr3 时钟正信号
    output                  ddr3_ck_n           , // ddr3 时钟负信号
    output                  ddr3_cke            , // ddr3 时钟使能
    output                  ddr3_cs_n           , // ddr3 片选信号，低电平有效
    output  [ 1:0]          ddr3_dm             , // ddr3 数据掩码
    output                  ddr3_odt            , // ddr3 输出驱动使能
    // ddr3 应用接口 ---------------------------------------------------------------
    output                  init_calib_complete , // ddr3 初始化和校准完成信号
    input   [ 15:0]         app_wdf_mask        , // 应用写数据掩码
    input   [ 27:0]         app_addr            , // 应用地址
    input   [  2:0]         app_cmd             , // 应用命令，读001，写000
    input                   app_en              , // 应用使能
    input   [127:0]         app_wdf_data        , // 应用写数据
    input                   app_wdf_end         , // 应用写数据结束
    input                   app_wdf_wren        , // 应用写使能
    output                  app_rdy             , // 应用就绪
    output                  app_wdf_rdy         , // 应用写数据就绪
    output  [127:0]         app_rd_data         , // 应用读数据
    output                  app_rd_data_valid   , // 应用读数据有效
    output                  ui_clk              ,
    output                  ui_clk_sync_rst     

);

//              main code
// ddr3 ip核 Memory Interface Generator
mig_7series_0 u_mig_7series_0 (
    // Memory interface ports
    .ddr3_addr                      (ddr3_addr          ),  // 输出 [13:0] DDR3地址
    .ddr3_ba                        (ddr3_ba            ),  // 输出 [2:0] ddr3 Bank地址
    .ddr3_cas_n                     (ddr3_cas_n         ),  // 输出 DDR3列地址选通信号，低电平有效
    .ddr3_ck_n                      (ddr3_ck_n          ),  // 输出 [0:0] DDR3时钟负信号
    .ddr3_ck_p                      (ddr3_ck_p          ),  // 输出 [0:0] DDR3时钟正信号
    .ddr3_cke                       (ddr3_cke           ),  // 输出 [0:0] DDR3时钟使能
    .ddr3_ras_n                     (ddr3_ras_n         ),  // 输出 DDR3行地址选通信号，低电平有效
    .ddr3_reset_n                   (ddr3_reset_n       ),  // 输出 DDR3复位信号，低电平有效
    .ddr3_we_n                      (ddr3_we_n          ),  // 输出 DDR3写使能信号，低电平有效
    .ddr3_dq                        (ddr3_dq            ),  // 双向 [15:0] DDR3数据线
    .ddr3_dqs_n                     (ddr3_dqs_n         ),  // 双向 [1:0] DDR3数据选通负信号
    .ddr3_dqs_p                     (ddr3_dqs_p         ),  // 双向 [1:0] DDR3数据选通正信号
    .init_calib_complete            (init_calib_complete),  // 输出 DDR3初始化和校准完成信号
    .ddr3_cs_n                      (ddr3_cs_n          ),  // 输出 [0:0] DDR3片选信号，低电平有效
    .ddr3_dm                        (ddr3_dm            ),  // 输出 [1:0] DDR3数据掩码
    .ddr3_odt                       (ddr3_odt           ),  // 输出 [0:0] DDR3输出驱动使能

    // Application interface ports
    .app_addr                       (app_addr           ),  // 输入 [27:0] 应用地址
    .app_cmd                        (app_cmd            ),  // 输入 [2:0] 应用命令，读001，写000
    .app_en                         (app_en             ),  // 输入 应用使能
    .app_wdf_data                   (app_wdf_data       ),  // 输入 [127:0] 应用写数据
    .app_wdf_end                    (app_wdf_end        ),  // 输入 应用写数据结束
    .app_wdf_wren                   (app_wdf_wren       ),  // 输入 应用写使能

    .app_rd_data                    (app_rd_data        ),  // 输出 [127:0] 应用读数据
    .app_rd_data_end                (                   ),  // 输出 应用读数据结束
    .app_rd_data_valid              (app_rd_data_valid  ),  // 输出 应用读数据有效
    .app_rdy                        (app_rdy            ),  // 输出 应用就绪
    .app_wdf_rdy                    (app_wdf_rdy        ),  // 输出 应用写数据就绪

    .app_sr_req                     (1'd0               ),  // 输入 应用自刷新请求
    .app_ref_req                    (1'd0               ),  // 输入 应用刷新请求
    .app_zq_req                     (1'd0               ),  // 输入 应用ZQ校准请求

    .app_sr_active                  (                   ),  // 输出 应用自刷新激活
    .app_ref_ack                    (                   ),  // 输出 应用刷新确认
    .app_zq_ack                     (                   ),  // 输出 应用ZQ校准确认
    .ui_clk                         (ui_clk             ),  // 输出 用户界面时钟
    .ui_clk_sync_rst                (ui_clk_sync_rst    ),  // 输出 用户界面时钟同步复位，高电平有效

    .app_wdf_mask                   (app_wdf_mask       ),  // 输入 [15:0] 应用写数据掩码

    // System Clock Ports
    .sys_clk_i                      (clk_200m           ),  // 输入 系统时钟
    .sys_rst                        (sys_rst_n          )   // 输入 系统复位（低电平有效）
);
endmodule