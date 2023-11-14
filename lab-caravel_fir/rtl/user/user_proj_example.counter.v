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
    parameter BITS     = 32,
    parameter DELAYS   = 10,
    parameter DATA_LEN = 11
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
    wire        wb_valid;
    wire [ 3:0] wb_wstrb;
    assign wb_valid = wbs_cyc_i && wbs_stb_i;
    assign wb_wstrb = wbs_sel_i & {4{wbs_we_i}};

    localparam BW = $clog2(DELAYS+2);
    reg           wbs_ack_o_r, wbs_ack_o_w;
    reg  [  31:0] wbs_dat_o_r, wbs_dat_o_w;
    reg  [BW-1:0] count_r, count_w;

    assign wbs_ack_o = wbs_ack_o_r;
    assign wbs_dat_o = wbs_dat_o_r;

    // exmem interface
    reg  [ 3:0] exmem_wstrb;
    reg         exmem_valid;
    reg  [31:0] exmem_dat_i;
    wire [31:0] exmem_rdata;
    reg  [31:0] exmem_adr_i;

    // AXI interface
    reg                axil_valid;
    reg                axis_valid;
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

    // data counter
    localparam DBW = $clog2(DATA_LEN+1);
    reg  [DBW-1:0] data_cnt_r, data_cnt_w;

    // WB decode
    always @(*) begin
        exmem_wstrb = 0;
        exmem_valid = 0;
        exmem_dat_i = 0;
        exmem_adr_i = 0;
        axil_valid  = 0;
        axis_valid  = 0;

        if (wbs_adr_i[31:16] == 16'h3000) begin
            if (wbs_adr_i[7:0] < 8'h80) begin
                axil_valid = 1;
            end
            else begin
                axis_valid = 1;
            end
        end
        else if (wbs_adr_i[31:16] == 16'h3800) begin
            exmem_wstrb = wb_wstrb;
            exmem_valid = wb_valid;
            exmem_dat_i = wbs_dat_i;
            exmem_adr_i = wbs_adr_i;
        end
    end

    // WB <-> AXI
    always @(*) begin
        awvalid   = 0;
        awaddr    = 0;
        wvalid    = 0;
        wdata     = 0;
        rready    = 0;
        arvalid   = 0;
        araddr    = 0;
        ss_tvalid = 0;
        ss_tdata  = 0;
        ss_tlast  = 0;
        sm_tready = 0;

        if (axil_valid) begin
            awvalid = wb_valid && wbs_we_i;
            awaddr  = (wbs_adr_i - 32'h3000_0000);
            wvalid  = wb_valid && wbs_we_i;
            wdata   = wbs_dat_i;

            rready  = wb_valid && (~wbs_we_i) && rvalid;
            arvalid = wb_valid && (~wbs_we_i);
            araddr  = (wbs_adr_i - 32'h3000_0000);
        end
        else if (axis_valid) begin
            ss_tvalid = wb_valid && wbs_we_i;
            ss_tdata  = wbs_dat_i;
            ss_tlast  = (data_cnt_r == DATA_LEN);
            sm_tready = wb_valid && (~wbs_we_i);
        end
    end

    // exmem-fir and verilog-fir
    always @(*) begin
        count_w     = count_r;
        wbs_ack_o_w = 0;
        wbs_dat_o_w = 0;

        if (exmem_valid && !wbs_ack_o_r) begin
            if (count_r == (DELAYS + 2)) begin
                count_w     = 0;
                wbs_ack_o_w = 1;
                wbs_dat_o_w = exmem_rdata;
            end
            else begin
                count_w     = count_r + 1;
                wbs_ack_o_w = 0;
                wbs_dat_o_w = 0;
            end
        end
        else if (axil_valid) begin
            wbs_ack_o_w = wbs_we_i ? (awready & wready) : rvalid;
            wbs_dat_o_w = wbs_we_i ? 0 : rdata;
        end
        else if (axis_valid) begin
            wbs_ack_o_w = wbs_we_i ? ss_tready : sm_tvalid;
            wbs_dat_o_w = wbs_we_i ? 0 : sm_tdata;
        end
    end

    // data counter
    always @(*) begin
        data_cnt_w = data_cnt_r;
        if (axis_valid) begin
            if (ss_tlast) begin
                data_cnt_w = 0;
            end
            else if (sm_tready & sm_tvalid) begin
                data_cnt_w = data_cnt_r + 1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            count_r     <= 0;
            data_cnt_r  <= 0;
            wbs_ack_o_r <= 0;
            wbs_dat_o_r <= 0;
        end
        else begin
            count_r     <= count_w;
            data_cnt_r  <= data_cnt_w;
            wbs_ack_o_r <= wbs_ack_o_w;
            wbs_dat_o_r <= wbs_dat_o_w;
        end
    end

    bram user_bram (
        .CLK (clk         ),
        .WE0 (exmem_wstrb ),
        .EN0 (exmem_valid ),
        .Di0 (exmem_dat_i ),
        .Do0 (exmem_rdata ),
        .A0  (exmem_adr_i )
    );

    fir_wrapper # (
        .pADDR_WIDTH (12 ),
        .pDATA_WIDTH (32 ),
        .Tape_Num    (11 )
    ) fir_wrapper_inst (
        .awready    (awready      ),
        .wready     (wready       ),
        .awvalid    (awvalid      ),
        .awaddr     (awaddr[11:0] ),
        .wvalid     (wvalid       ),
        .wdata      (wdata        ),
        .arready    (arready      ),
        .rready     (rready       ),
        .arvalid    (arvalid      ),
        .araddr     (araddr[11:0] ),
        .rvalid     (rvalid       ),
        .rdata      (rdata        ),
        .ss_tvalid  (ss_tvalid    ),
        .ss_tdata   (ss_tdata     ),
        .ss_tlast   (ss_tlast     ),
        .ss_tready  (ss_tready    ),
        .sm_tready  (sm_tready    ),
        .sm_tvalid  (sm_tvalid    ),
        .sm_tdata   (sm_tdata     ),
        .sm_tlast   (sm_tlast     ),
        .axis_clk   (clk          ),
        .axis_rst_n (~rst         )
    );

endmodule


`default_nettype wire
