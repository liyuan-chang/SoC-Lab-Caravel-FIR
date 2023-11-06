// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32,
    parameter DELAYS=10
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    assign clk = wb_clk_i;
    assign rst = wb_rst_i;

    // LA, IRQ, IOS are unused
    assign la_data_out = 0;
    assign io_out = 0;
    assign io_oeb = 0;
    assign irq = 3'd0;

    // WB interface
    wire        valid;
    wire [ 3:0] wstrb;
    assign valid = wbs_cyc_i && wbs_stb_i;
    assign wstrb = wbs_sel_i & {4{wbs_we_i}};

    localparam BW = $clog2(DELAYS+2);
    wire [  31:0] rdata;
    reg           wbs_ack_o_r, wbs_ack_o_w;
    reg  [  31:0] wbs_dat_o_r, wbs_dat_o_w;
    reg  [BW-1:0] count_r, count_w;

    assign wbs_ack_o = wbs_ack_o_r;
    assign wbs_dat_o = wbs_dat_o_r;

    // AXI interface
    wire               awready;
    wire               wready;
    reg                awvalid;
    reg         [31:0] awaddr;
    reg                wvalid;
    reg  signed [31:0] wdata;
    wire               arready;
    reg                rready;
    reg                arvalid;
    reg         [31:0] araddr;
    wire               rvalid;
    wire signed [31:0] rdata;
    reg                ss_tvalid;
    reg  signed [31:0] ss_tdata;
    reg                ss_tlast;
    wire               ss_tready;
    reg                sm_tready;
    wire               sm_tvalid;
    wire signed [31:0] sm_tdata;
    wire               sm_tlast;

    always @(*) begin
        count_w     = count_r;
        wbs_ack_o_w = 0;
        wbs_dat_o_w = 0;

        if (valid && !wbs_ack_o_r) begin
            if (count_r == (DELAYS + 2)) begin
                count_w     = 0;
                wbs_ack_o_w = 1;
                wbs_dat_o_w = rdata;
            end
            else begin
                count_w     = count_r + 1;
                wbs_ack_o_w = 0;
                wbs_dat_o_w = 0;
            end
            
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            count_r     <= 0;
            wbs_ack_o_r <= 0;
            wbs_dat_o_r <= 0;
        end
        else begin
            count_r     <= count_w;
            wbs_ack_o_r <= wbs_ack_o_w;
            wbs_dat_o_r <= wbs_dat_o_w;
        end
    end

    bram user_bram (
        .CLK (clk       ),
        .WE0 (wstrb     ),
        .EN0 (valid     ),
        .Di0 (wbs_dat_i ),
        .Do0 (rdata     ),
        .A0  (wbs_adr_i )
    );

    fir_wrapper # (
        .pADDR_WIDTH (32 ),
        .pDATA_WIDTH (32 ),
        .Tape_Num    (11 )
    ) fir_wrapper_inst (
        .awready    (awready   ),
        .wready     (wready    ),
        .awvalid    (awvalid   ),
        .awaddr     (awaddr    ),
        .wvalid     (wvalid    ),
        .wdata      (wdata     ),
        .arready    (arready   ),
        .rready     (rready    ),
        .arvalid    (arvalid   ),
        .araddr     (araddr    ),
        .rvalid     (rvalid    ),
        .rdata      (rdata     ),
        .ss_tvalid  (ss_tvalid ),
        .ss_tdata   (ss_tdata  ),
        .ss_tlast   (ss_tlast  ),
        .ss_tready  (ss_tready ),
        .sm_tready  (sm_tready ),
        .sm_tvalid  (sm_tvalid ),
        .sm_tdata   (sm_tdata  ),
        .sm_tlast   (sm_tlast  ),
        .axis_clk   (clk       ),
        .axis_rst_n (~rst      )
    );

endmodule


`default_nettype wire
