module ov5640_dri (
    input sys_clk,
    input sys_rst_n,
    input [23:0] sccb_data, // [23:8]�ǼĴ����ĵ�ַ��[7:0] �ǼĴ���������
    input sccb_exc,
    output reg sccb_done,
    output reg sccb_clk,
);
    
endmodule