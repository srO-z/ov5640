module ov5640_dri #(
    parameter
        SCCB_SCL_FRQ = 32'd50_000,
        SYS_CLK_FRQ = 32'd50_000_000
)(
    input               clk         , // 50MHz
    input               rst_n       ,
    input      [23:0]   sccb_data   , // [23:8]是寄存器的地址，[7:0] 是寄存器的数据
    input               sccb_exc    ,
    input               sccb_rw     , // 1：读；0：写
    output reg          sccb_done   ,
    output reg          sccb_clk    ,
    inout               sccb_sda    ,
    output reg          dri_clk     
);
// parameter define
localparam
    IDLE        = 6'b000001,
    ADDR_IC     = 6'b000010,
    ADDR_REG    = 6'b000100,
    WRITE       = 6'b001000,
    READ        = 6'b010000,
    DONE        = 6'b100000;

// reg define
reg [10:0] dri_cnt;
reg [7:0] cnt;
reg [5:0] cur_state, next_state;
reg skip;
//              main code 
// dri_clk 设置 default: 200kHz
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        dri_cnt <= 11'd0;
        dri_clk <= 1'd0;
    end
    else begin
        if(dri_cnt == (SYS_CLK_FRQ / (SCCB_SCL_FRQ*4))*2)begin
            dri_cnt <= 11'd0;
            dri_clk <= ~dri_clk;
        end
        else
            dri_cnt <= dri_cnt + 11'd1;
    end
end

// 状态机第一段，状态转移
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        cur_state <= IDLE;
    else
        cur_state <= next_state;
end

// 状态机第二段，状态判断
always @(*) begin
    case (cur_state)
        IDLE    : next_state = skip ? ADDR_IC  : IDLE    ;
        ADDR_IC : next_state = skip ? ADDR_REG : ADDR_IC ;
        ADDR_REG: next_state = skip ? WRITE    : ADDR_REG;
        WRITE   : next_state = skip ? READ     : WRITE   ;
        READ    : next_state = skip ? DONE     : READ    ;
        DONE    : next_state = skip ? IDLE     : DONE    ;
    endcase
end
endmodule
