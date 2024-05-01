module ov5640_dri (
    input sys_clk,
    input sys_rst_n,
    input [23:0] sccb_data, // [23:8]是寄存器的地址，[7:0] 是寄存器的数据
    input sccb_exc,
    output reg sccb_done,
    output reg sccb_clk,
);
    
endmodule