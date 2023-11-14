module fir_wrapper # (
    parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)(
    output wire                            awready,
    output wire                            wready,
    input  wire                            awvalid,
    input  wire        [(pADDR_WIDTH-1):0] awaddr,
    input  wire                            wvalid,
    input  wire signed [(pDATA_WIDTH-1):0] wdata,
    output wire                            arready,
    input  wire                            rready,
    input  wire                            arvalid,
    input  wire        [(pADDR_WIDTH-1):0] araddr,
    output wire                            rvalid,
    output wire signed [(pDATA_WIDTH-1):0] rdata,
    input  wire                            ss_tvalid,
    input  wire signed [(pDATA_WIDTH-1):0] ss_tdata,
    input  wire                            ss_tlast,
    output wire                            ss_tready,
    input  wire                            sm_tready,
    output wire                            sm_tvalid,
    output wire signed [(pDATA_WIDTH-1):0] sm_tdata,
    output wire                            sm_tlast,
    input  wire                            axis_clk,
    input  wire                            axis_rst_n
);
    // ram interface for tap
    wire                     tap_WE;
    wire                     tap_EN;
    wire [(pDATA_WIDTH-1):0] tap_Di;
    wire [(pADDR_WIDTH-1):0] tap_A;
    wire [(pDATA_WIDTH-1):0] tap_Do;

    // ram interface for data
    wire                     data_WE;
    wire                     data_EN;
    wire [(pDATA_WIDTH-1):0] data_Di;
    wire [(pADDR_WIDTH-1):0] data_A;
    wire [(pDATA_WIDTH-1):0] data_Do;

    fir fir_inst(
        .awready (awready ),
        .wready  (wready  ),
        .awvalid (awvalid ),
        .awaddr  (awaddr  ),
        .wvalid  (wvalid  ),
        .wdata   (wdata   ),
        .arready (arready ),
        .rready  (rready  ),
        .arvalid (arvalid ),
        .araddr  (araddr  ),
        .rvalid  (rvalid  ),
        .rdata   (rdata   ),

        .ss_tvalid (ss_tvalid ),
        .ss_tdata  (ss_tdata  ),
        .ss_tlast  (ss_tlast  ),
        .ss_tready (ss_tready ),

        .sm_tready (sm_tready ),
        .sm_tvalid (sm_tvalid ),
        .sm_tdata  (sm_tdata  ),
        .sm_tlast  (sm_tlast  ),

        // ram for tap
        .tap_WE (tap_WE ),
        .tap_EN (tap_EN ),
        .tap_Di (tap_Di ),
        .tap_A  (tap_A  ),
        .tap_Do (tap_Do ),

        // ram for data
        .data_WE (data_WE ),
        .data_EN (data_EN ),
        .data_Di (data_Di ),
        .data_A  (data_A  ),
        .data_Do (data_Do ),

        .axis_clk   (axis_clk   ),
        .axis_rst_n (axis_rst_n )
    );
    
    // RAM for tap
    bram11 tap_RAM (
        .clk   (axis_clk           ),
        .we    (tap_WE             ),
        .re    (tap_EN & (~tap_WE) ),
        .wdi   (tap_Di             ),
        .waddr ((tap_A >> 2)       ),  // word address
        .raddr ((tap_A >> 2)       ),  // word address
        .rdo   (tap_Do             )
    );

    // RAM for data: choose bram11 or bram12
    bram11 data_RAM(
        .clk   (axis_clk             ),
        .we    (data_WE              ),
        .re    (data_EN & (~data_WE) ),
        .wdi   (data_Di              ),
        .waddr ((data_A >> 2)        ),  // word address
        .raddr ((data_A >> 2)        ),  // word address
        .rdo   (data_Do              )
    );

endmodule
