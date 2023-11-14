`timescale 1ns / 1ps
//`define MPRJ_IO_PADS 32
module fir_wrapper (  
    input           wb_clk_i,
    input           wb_rst_i,
    input           wbs_stb_i,
    input           wbs_cyc_i,
    input           wbs_we_i,
    input   [3:0]   wbs_sel_i,
    input  [31:0]   wbs_dat_i,
    input  [31:0]   wbs_adr_i,
    output reg          wbs_ack_o,
    output reg [31:0]   wbs_dat_o

);
 



// axi_lite write
wire awready, wready;
reg awvalid, wvalid, awvalid_w, wvalid_w;
reg [11:0] awaddr,   awaddr_w;
reg [31:0] wdata,   wdata_w;



// axi_lite read
reg  rready, arvalid , rready_w, arvalid_w;
wire  arready, rvalid;
reg  [11:0] araddr,araddr_w;
wire [31:0] rdata;


// axi_s slave (write)
wire  ss_tready;
reg ss_tvalid ,ss_tvalid_w;
reg [31:0] ss_tdata, ss_tdata_w;


// axi_s master (read)
reg sm_tready,sm_tready_w;
wire        sm_tvalid;
wire [31:0] sm_tdata;


// tap_ram
wire [3:0]  tap_WE;
wire        tap_EN;
wire [11:0] tap_A;
wire [31:0] tap_Di, tap_Do;

// ctrl
wire axil_valid,axis_valid;
wire read; // 1: read, 0: write

wire wb_valid;

reg wbs_ack_o_w;
reg [31:0] wbs_dat_o_w;

assign axil_valid = (wbs_adr_i[31:24] == 8'h30) && (wbs_adr_i[7:4] < 4'h8);
assign axis_valid = (wbs_adr_i[31:24] == 8'h30) && (wbs_adr_i[7:4] == 4'h8);



bram11 tap_ram(
    .clk(wb_clk_i),
    .we(|tap_WE),
    .re(tap_EN),
    .waddr(tap_A),
    .raddr(tap_A),
    .wdi(tap_Di),
    .rdo(tap_Do)
);

// data_ram
wire [3:0]  data_WE;
wire        data_EN;
wire [11:0] data_A;
wire [31:0] data_Di, data_Do;
bram11 data_ram(
    .clk(wb_clk_i),
    .we(|data_WE),
    .re(data_EN),
    .waddr(data_A),
    .raddr(data_A),
    .wdi(data_Di),
    .rdo(data_Do)
);

// fir_module
fir inst_fir(
    .awready(awready),
    .wready(wready),
    .awvalid(awvalid),
    .awaddr(awaddr),
    .wvalid(wvalid),
    .wdata(wdata),
    .arready(arready),
    .rready(rready),
    .arvalid(arvalid),
    .araddr(araddr),
    .rvalid(rvalid),
    .rdata(rdata),    
    .ss_tvalid(ss_tvalid), 
    .ss_tdata(ss_tdata), 
    .ss_tlast(), 
    .ss_tready(ss_tready), 
    .sm_tready(sm_tready), 
    .sm_tvalid(sm_tvalid), 
    .sm_tdata(sm_tdata), 
    .sm_tlast(), 
    
    .tap_WE(tap_WE),
    .tap_EN(tap_EN),
    .tap_Di(tap_Di),
    .tap_A(tap_A),
    .tap_Do(tap_Do),
    
    .data_WE(data_WE),
    .data_EN(data_EN),
    .data_Di(data_Di),
    .data_A(data_A),
    .data_Do(data_Do),

    .axis_clk(wb_clk_i),
    .axis_rst_n(~wb_rst_i)
);

// axi_lite write
reg [2:0] axilw_state_w, axilw_state_r;
reg axilw_ack;
always @(*) begin
    awvalid_w = 0;
    wvalid_w = 0;
    awaddr_w = awaddr;
    wdata_w = wdata;
    axilw_state_w = axilw_state_r;
    axilw_ack = 0;
    case (axilw_state_r)
        0:begin
            if (wbs_stb_i && wbs_cyc_i && (wbs_we_i) && axil_valid) begin
                awvalid_w = 1;
                wvalid_w = 1;
                awaddr_w = wbs_adr_i[11:0];
                wdata_w = wbs_dat_i[31:0];
                axilw_state_w = 1;
            end
        end 
        1:begin
            if (awready && wready) begin
                awvalid_w = 0;
                wvalid_w = 0;
                axilw_state_w = 2;
                axilw_ack = 1;
            end
        end
        2: axilw_state_w = 0;
    endcase
end

// axi_lite read
reg [1:0] axilr_state_w, axilr_state_r;
reg [31:0] axilr_data_w, axilr_data_r;
reg axilr_ack;
always @(*) begin
    arvalid_w = 0;
    rready_w = 0;
    araddr_w = araddr;
    axilr_state_w = axilr_state_r;
    axilr_data_w = axilr_data_r;
    axilr_ack = 0;
    case (axilr_state_r)
        0:begin
            if (wbs_stb_i && wbs_cyc_i && (~wbs_we_i) && axil_valid) begin
                arvalid_w = 1;
                araddr_w = wbs_adr_i[11:0];
                axilr_state_w = 1;
            end
        end 
        1:begin
            arvalid_w = 1;
            if (arready) begin
                arvalid_w = 0;
                axilr_state_w = 2;
                rready_w = 1;
            end
        end
        2:begin
            if (rvalid) begin
                axilr_data_w = rdata;
                axilr_state_w = 3;
                axilr_ack = 1;
            end
        end
        3: axilr_state_w = 0;
    endcase
end

// axi_s slave (write)
reg [1:0] ss_state_w, ss_state_r;
reg ss_ack;

always @(*) begin
    ss_tvalid_w = 0;
    ss_tdata_w = ss_tdata;
    ss_state_w = ss_state_r;
    ss_ack = 0;
    case (ss_state_r)
        0:begin
            if (wbs_stb_i && wbs_cyc_i && (wbs_we_i) && axis_valid) begin
                ss_tvalid_w = 1;
                ss_tdata_w = wbs_dat_i[31:0];
                ss_state_w = 1;
            end
        end 
        1:begin
            if (ss_tready) begin
                ss_tvalid_w = 0;
                ss_state_w = 2;
                ss_ack = 1;
            end
        end
        2: ss_state_w = 0;
    endcase
end

// axi_s master (read)
reg [1:0] sm_state_w, sm_state_r;
reg sm_ack;
reg [31:0] sm_data_buf_w, sm_data_buf_r;
always @(*) begin
    sm_tready_w = 0;
    sm_state_w = sm_state_r;
    sm_ack = 0;
    sm_data_buf_w = sm_data_buf_r;
    case (sm_state_r)
        0:begin
            if (wbs_stb_i && wbs_cyc_i && (~wbs_we_i) && axis_valid) begin
                sm_tready_w = 1;
                sm_state_w = 1;
            end
        end 
        1:begin
            sm_tready_w = 1;
            if (sm_tvalid) begin
                sm_data_buf_w = sm_tdata;
                sm_ack = 1;
                sm_state_w = 2;
            end
        end
        2:sm_state_w = 0;
    endcase

end

always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if (wb_rst_i)begin
        wbs_ack_o <= 0;
        wbs_dat_o <= 0;

        awvalid <= 0;
        wvalid <= 0;
        awaddr <= 0;
        wdata <= 0;

        arvalid <= 0;
        rready <= 0;
        araddr <= 0;

        ss_tvalid <= 0;
        ss_tdata <= 0;

        sm_tready <= 0;


        axilw_state_r <= 0;
        axilr_state_r <= 0;
        axilr_data_r <= 0;

        ss_state_r <= 0;
        sm_state_r <= 0;
        sm_data_buf_r <= 0;

    end
    else begin
        wbs_ack_o <= (axilw_ack || axilr_ack || ss_ack || sm_ack);
        wbs_dat_o <= axis_valid ? sm_data_buf_w : axilr_data_w;

        awvalid <= awvalid_w;
        wvalid <= wvalid_w;
        awaddr <= awaddr_w;
        wdata <= wdata_w;

        arvalid <= arvalid_w;
        rready <= rready_w;
        araddr <= araddr_w;

        ss_tvalid <= ss_tvalid_w;
        ss_tdata <= ss_tdata_w;

        sm_tready <= sm_tready_w;

        axilw_state_r <= axilw_state_w;
        axilr_state_r <= axilr_state_w;
        axilr_data_r <= axilr_data_w;

        ss_state_r <= ss_state_w;
        sm_state_r <= sm_state_w;
        sm_data_buf_r <= sm_data_buf_w;

    end
end




endmodule
