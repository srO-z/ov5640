// ����200MHz���ڲ�ʱ��400MHz���û���100MHz
module ddr3_ctrller (
    // system ---------------------------------------------------------------------
    input                   clk_200m            , // 200Mhz
    input                   sys_rst_n           , // ��λ���͵�ƽ��Ч
    // ddr3 ��·�ӿ� ---------------------------------------------------------------
    inout   [15:0]          ddr3_dq             , // ddr3 ������
    inout   [ 1:0]          ddr3_dqs_n          , // ddr3 ����ѡͨ���ź�
    inout   [ 1:0]          ddr3_dqs_p          , // ddr3 ����ѡͨ���ź�
    output  [13:0]          ddr3_addr           , // ddr3 ��ַ��
    output  [ 2:0]          ddr3_ba             , // ddr3 Bank��ַ
    output                  ddr3_ras_n          , // ddr3 �е�ַѡͨ�źţ��͵�ƽ��Ч
    output                  ddr3_cas_n          , // ddr3 �е�ַѡͨ�źţ��͵�ƽ��Ч
    output                  ddr3_we_n           , // ddr3 дʹ���źţ��͵�ƽ��Ч
    output                  ddr3_reset_n        , // ddr3 ��λ�źţ��͵�ƽ��Ч
    output                  ddr3_ck_p           , // ddr3 ʱ�����ź�
    output                  ddr3_ck_n           , // ddr3 ʱ�Ӹ��ź�
    output                  ddr3_cke            , // ddr3 ʱ��ʹ��
    output                  ddr3_cs_n           , // ddr3 Ƭѡ�źţ��͵�ƽ��Ч
    output  [ 1:0]          ddr3_dm             , // ddr3 ��������
    output                  ddr3_odt            , // ddr3 �������ʹ��
    // ddr3 Ӧ�ýӿ� ---------------------------------------------------------------
    output                  init_calib_complete , // ddr3 ��ʼ����У׼����ź�
    input   [ 15:0]         app_wdf_mask        , // Ӧ��д��������
    input   [ 27:0]         app_addr            , // Ӧ�õ�ַ
    input   [  2:0]         app_cmd             , // Ӧ�������001��д000
    input                   app_en              , // Ӧ��ʹ��
    input   [127:0]         app_wdf_data        , // Ӧ��д����
    input                   app_wdf_end         , // Ӧ��д���ݽ���
    input                   app_wdf_wren        , // Ӧ��дʹ��
    output                  app_rdy             , // Ӧ�þ���
    output                  app_wdf_rdy         , // Ӧ��д���ݾ���
    output  [127:0]         app_rd_data         , // Ӧ�ö�����
    output                  app_rd_data_valid   , // Ӧ�ö�������Ч
    output                  ui_clk              ,
    output                  ui_clk_sync_rst     

);

//              main code
// ddr3 ip�� Memory Interface Generator
mig_7series_0 u_mig_7series_0 (
    // Memory interface ports
    .ddr3_addr                      (ddr3_addr          ),  // ��� [13:0] DDR3��ַ
    .ddr3_ba                        (ddr3_ba            ),  // ��� [2:0] ddr3 Bank��ַ
    .ddr3_cas_n                     (ddr3_cas_n         ),  // ��� DDR3�е�ַѡͨ�źţ��͵�ƽ��Ч
    .ddr3_ck_n                      (ddr3_ck_n          ),  // ��� [0:0] DDR3ʱ�Ӹ��ź�
    .ddr3_ck_p                      (ddr3_ck_p          ),  // ��� [0:0] DDR3ʱ�����ź�
    .ddr3_cke                       (ddr3_cke           ),  // ��� [0:0] DDR3ʱ��ʹ��
    .ddr3_ras_n                     (ddr3_ras_n         ),  // ��� DDR3�е�ַѡͨ�źţ��͵�ƽ��Ч
    .ddr3_reset_n                   (ddr3_reset_n       ),  // ��� DDR3��λ�źţ��͵�ƽ��Ч
    .ddr3_we_n                      (ddr3_we_n          ),  // ��� DDR3дʹ���źţ��͵�ƽ��Ч
    .ddr3_dq                        (ddr3_dq            ),  // ˫�� [15:0] DDR3������
    .ddr3_dqs_n                     (ddr3_dqs_n         ),  // ˫�� [1:0] DDR3����ѡͨ���ź�
    .ddr3_dqs_p                     (ddr3_dqs_p         ),  // ˫�� [1:0] DDR3����ѡͨ���ź�
    .init_calib_complete            (init_calib_complete),  // ��� DDR3��ʼ����У׼����ź�
    .ddr3_cs_n                      (ddr3_cs_n          ),  // ��� [0:0] DDR3Ƭѡ�źţ��͵�ƽ��Ч
    .ddr3_dm                        (ddr3_dm            ),  // ��� [1:0] DDR3��������
    .ddr3_odt                       (ddr3_odt           ),  // ��� [0:0] DDR3�������ʹ��

    // Application interface ports
    .app_addr                       (app_addr           ),  // ���� [27:0] Ӧ�õ�ַ
    .app_cmd                        (app_cmd            ),  // ���� [2:0] Ӧ�������001��д000
    .app_en                         (app_en             ),  // ���� Ӧ��ʹ��
    .app_wdf_data                   (app_wdf_data       ),  // ���� [127:0] Ӧ��д����
    .app_wdf_end                    (app_wdf_end        ),  // ���� Ӧ��д���ݽ���
    .app_wdf_wren                   (app_wdf_wren       ),  // ���� Ӧ��дʹ��

    .app_rd_data                    (app_rd_data        ),  // ��� [127:0] Ӧ�ö�����
    .app_rd_data_end                (                   ),  // ��� Ӧ�ö����ݽ���
    .app_rd_data_valid              (app_rd_data_valid  ),  // ��� Ӧ�ö�������Ч
    .app_rdy                        (app_rdy            ),  // ��� Ӧ�þ���
    .app_wdf_rdy                    (app_wdf_rdy        ),  // ��� Ӧ��д���ݾ���

    .app_sr_req                     (1'd0               ),  // ���� Ӧ����ˢ������
    .app_ref_req                    (1'd0               ),  // ���� Ӧ��ˢ������
    .app_zq_req                     (1'd0               ),  // ���� Ӧ��ZQУ׼����

    .app_sr_active                  (                   ),  // ��� Ӧ����ˢ�¼���
    .app_ref_ack                    (                   ),  // ��� Ӧ��ˢ��ȷ��
    .app_zq_ack                     (                   ),  // ��� Ӧ��ZQУ׼ȷ��
    .ui_clk                         (ui_clk             ),  // ��� �û�����ʱ��
    .ui_clk_sync_rst                (ui_clk_sync_rst    ),  // ��� �û�����ʱ��ͬ����λ���ߵ�ƽ��Ч

    .app_wdf_mask                   (app_wdf_mask       ),  // ���� [15:0] Ӧ��д��������

    // System Clock Ports
    .sys_clk_i                      (clk_200m           ),  // ���� ϵͳʱ��
    .sys_rst                        (sys_rst_n          )   // ���� ϵͳ��λ���͵�ƽ��Ч��
);
endmodule