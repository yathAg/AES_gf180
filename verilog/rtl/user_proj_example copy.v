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
    parameter BITS = 16
)(
`ifdef USE_POWER_PINS
    inout vdd,	// User area 1 1.8V supply
    inout vss,	// User area 1 digital ground
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
    output reg wbs_ack_o,
    output reg [31:0] wbs_dat_o,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

);
    wire clk;
    wire rst;

    // IO
    assign io_out = aes_dout;
    assign io_oeb = ~{(`MPRJ_IO_PADS-1){rst}};  //doubt

    assign clk =  wb_clk_i;
    assign rst =  wb_rst_i;

    // AES Signals
    wire [31:0] aes_dout;
    wire [31:0] aes_din;
    wire aes_cs;
    wire aes_we;

    assign aes_cs  = wbs_stb_i && wbs_cyc_i && ((wbs_adr_i[11:8] == 4'h0) || (wbs_adr_i[11:8] == 4'h9));
    assign aes_we  = wbs_stb_i && wbs_cyc_i && wbs_we_i && ((wbs_adr_i[11:8] == 4'h0) || (wbs_adr_i[11:8] == 4'h9));
    assign aes_din = (wbs_adr_i[11:8] == 4'h0) ? wbs_dat_i : 32'h0;    

    //WRITE REGS WITH WISHBOND

    //READ REGS WITH WISHBOND
	always @(posedge wb_clk_i) begin 
		if (wb_rst_i) begin
			wbs_dat_o <= 32'h0;
		end else if(wbs_stb_i && wbs_cyc_i && !wbs_we_i) begin
            if (wbs_adr_i[11:8] == 4'h0) begin
                wbs_dat_o <= aes_dout;
        end else begin
                wbs_dat_o <= 32'h0;
            end
            end
        end

    // ACK WISHBOND
    always @(posedge wb_clk_i) begin 
		if (wb_rst_i) begin
			wbs_ack_o <= 1'b0;
		end else begin
			wbs_ack_o <= (wbs_stb_i && wbs_cyc_i);
		end
    end

    //AES Instantiation
    aes aes_inst(
        // Clock and reset.
        .clk(clk),
        .reset_n(~rst),

        // Control.
        .cs(aes_cs),
        .we(aes_we),

        // Data ports.
        .address(wbs_adr_i[7:0]),
        .write_data(aes_din),
        .read_data(aes_dout)
    );

endmodule

`default_nettype wire
