module top (
    input           sys_clk         ,  

    // eth
    input           eth_rxc         ,
    input           eth_rxctl       ,
    input  [3:0]    eth_rxd         ,
    input           sys_rst_n       , // s0
    input           key_eth_rst_n   , // s1
    input           key_arp_req     , // s2
    input           key_udp_tx      , // s4
    output          eth_txc         ,
    output          eth_txctl       ,
    output [3:0]    eth_txd         ,
    output          eth_rst_n       ,

    // ov5640
    input           cam_pclk    ,  
    input  [7:0]    img_data    ,  
    input           coms_vsync  ,
    input           coms_href   , 
    output          sccb_scl    ,  
    inout           sccb_sda    ,  
    output          cam_rst_n   , 
    output          cam_pwdn    ,  
    output          cam_xclk    ,
    output [7:0]    led         ,

    // ddr3
    inout   [15:0]  ddr3_dq     ,
    inout   [ 1:0]  ddr3_dqs_n  ,
    inout   [ 1:0]  ddr3_dqs_p  ,
    output  [13:0]  ddr3_addr   ,
    output  [ 2:0]  ddr3_ba     ,
    output          ddr3_ras_n  ,
    output          ddr3_cas_n  ,
    output          ddr3_we_n   ,
    output          ddr3_reset_n,
    output          ddr3_ck_p   ,
    output          ddr3_ck_n   ,
    output          ddr3_cke    ,
    output          ddr3_cs_n   ,
    output  [ 1:0]  ddr3_dm     ,
    output          ddr3_odt    
);

wire clk_50m, clk_24m, clk_200m;
wire locked, locked1;
wire i2c_exec, i2c_done, init_done;
wire i2c_rh_wl;
wire [7:0] i2c_data_r;
wire [23:0] i2c_data;
wire dri_clk;
wire cam_clk;
wire udp_tx_start;
wire [7:0] udp_tx_data;
wire [15:0] udp_tx_byte_num;
wire fifo_rd_en;
wire udp_tx_done;
/*****************************************************
                        main code                       
*****************************************************/

assign eth_rst_n = 1'd1;
assign cam_rst_n = 1'd1;
assign cam_pwdn = 1'd0;
assign cam_xclk = clk_24m; 
assign led[5] = locked & locked1;
assign led[6] = init_done;
assign led[7] = 1'd1;


sys_clk_wiz u_sys_clk_wiz(
    .clk_out1(clk_50m),     
    .clk_out2(clk_24m), 
    .clk_out3(clk_200m), 
    .reset(~sys_rst_n), 
    .locked(locked),
    .clk_in1(sys_clk)
);

cam_pclk_wiz u_cam_pclk_wiz(
    .clk_out1(cam_clk),
    .reset(~sys_rst_n),
    .locked(locked1),
    .clk_in1(cam_pclk)
);

i2c_dri #(
    .SLAVE_ADDR(8'h3c),
    .CLK_FREQ(26'd50_000_000),
    .I2C_FREQ(18'd250_000)
) u_i2c_dri(
    .clk        (clk_50m),
    .rst_n      (sys_rst_n),
    .i2c_exec   (i2c_exec),
    .bit_ctrl   (1'd1),
    .i2c_rh_wl  (i2c_rh_wl),
    .i2c_addr   (i2c_data[23:8]),
    .i2c_data_w (i2c_data[7:0]),
    .i2c_data_r (i2c_data_r),
    .i2c_done   (i2c_done),
    .scl        (sccb_scl),
    .sda        (sccb_sda),
    .dri_clk    (dri_clk)
);    

i2c_ov5640_rgb565_cfg u_cfg(
    .clk            (dri_clk),
    .rst_n          (sys_rst_n),
    .i2c_data_r     (i2c_data_r),
    .i2c_done       (i2c_done),
    .cmos_h_pixel   (16'd640),
    .cmos_v_pixel   (16'd480),
    .total_h_pixel  (16'd1856),
    .total_v_pixel  (16'd984),
    .i2c_exec       (i2c_exec),
    .i2c_data       (i2c_data),
    .i2c_rh_wl      (i2c_rh_wl),
    .init_done      (init_done)
);

img_data_pkt u_pkt(
    .clk                (cam_pclk),
    .rst_n              (sys_rst_n),
    .img_data_i         (img_data),
    .img_href_i         (coms_href),
    .img_vsync_i        (coms_vsync),
    .init_done          (init_done),
    .ui_clk             (ui_clk),
    .fifo_rd_en         (),
    .ddr_fifo_rd_data   (),
    .frame_start        (),
    .ddr_exc            (),
    .led                ()
);

wire ddr_rw          ;
wire ddr_exc         ;
wire frame_start     ;
wire cam_fifo_rd_en  ;
wire cam_fifo_rd_data;
wire ddr_rd_done     ;
wire ddr_wr_done     ;
wire ddr_fifo_rd_en  ;
wire ddr_fifo_rd_data;
wire ui_clk          ;
ddr3 u_ddr3(
    .clk_200m           (clk_200m        ),
    .sys_rst_n          (sys_rst_n       ),
    .ddr3_dq            (ddr3_dq         ),
    .ddr3_dqs_n         (ddr3_dqs_n      ),
    .ddr3_dqs_p         (ddr3_dqs_p      ),
    .ddr3_addr          (ddr3_addr       ),
    .ddr3_ba            (ddr3_ba         ),
    .ddr3_ras_n         (ddr3_ras_n      ),
    .ddr3_cas_n         (ddr3_cas_n      ),
    .ddr3_we_n          (ddr3_we_n       ),
    .ddr3_reset_n       (ddr3_reset_n    ),
    .ddr3_ck_p          (ddr3_ck_p       ),
    .ddr3_ck_n          (ddr3_ck_n       ),
    .ddr3_cke           (ddr3_cke        ),
    .ddr3_cs_n          (ddr3_cs_n       ),
    .ddr3_dm            (ddr3_dm         ),
    .ddr3_odt           (ddr3_odt        ),
    .ddr_rw             (ddr_rw          ),
    .ddr_exc            (ddr_exc         ),
    .frame_start        (frame_start     ),
    .cam_fifo_rd_en     (cam_fifo_rd_en  ),
    .cam_fifo_rd_data   (cam_fifo_rd_data),
    .ddr_rd_done        (ddr_rd_done     ),
    .ddr_wr_done        (ddr_wr_done     ),
    .ddr_fifo_rd_en     (ddr_fifo_rd_en  ),
    .ddr_fifo_rd_data   (ddr_fifo_rd_data),
    .ui_clk             (ui_clk          )
);

eth_top u_eth(
    .eth_rxc            (eth_rxc),
    .eth_rxctl          (eth_rxctl),
    .eth_rxd            (eth_rxd),
    .sys_rst_n          (sys_rst_n),
    .key_eth_rst_n      (key_eth_rst_n),
    .key_arp_req        (key_arp_req),
    .key_udp_tx         (key_udp_tx),
    .tx_start           (udp_tx_start),
    .udp_fifo_rd_data   (udp_tx_data),
    .len_udp_data       (udp_tx_byte_num),
    .rd_data_count      (),
    .udp_fifo_rd_en     (fifo_rd_en),
    .udp_rx_data        (),
    .eth_txc            (eth_txc),
    .eth_txctl          (eth_txctl),
    .eth_txd            (eth_txd),
    // .eth_rst_n       (eth_rst_n),
    .led                (led[3:0]),
    .udp_tx_done        (udp_tx_done)
);
endmodule