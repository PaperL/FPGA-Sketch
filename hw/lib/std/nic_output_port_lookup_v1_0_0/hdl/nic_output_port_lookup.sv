//-
// Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
//                          Junior University
// Copyright (C) 2010, 2011 Adam Covington
// Copyright (C) 2015 Noa Zilberman
// All rights reserved.
//
// This software was developed by
// Stanford University and the University of Cambridge Computer Laboratory
// under National Science Foundation under Grant No. CNS-0855268,
// the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
// by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
// as part of the DARPA MRC research programme,
// and by the University of Cambridge Computer Laboratory under EPSRC EARL Project
// EP/P025374/1 alongside support from Xilinx Inc.
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@
//
/*******************************************************************************
 *  File:
 *        nic_output_port_lookup.v
 *
 *  Library:
 *        hw/std/cores/nic_output_port_lookup
 *
 *  Module:
 *        nic_output_port_lookup
 *
 *  Author:
 *        Adam Covington
 *        Modified by Noa Zilberman
 *
 *  Description:
 *        Output port lookup for the reference NIC project
 *
 */


`include "output_port_lookup_cpu_regs_defines.v"

module nic_output_port_lookup #(
    // Master AXI Stream Data Width
    parameter int unsigned C_M_AXIS_DATA_WIDTH = 512,
    parameter int unsigned C_S_AXIS_DATA_WIDTH = 512,
    parameter int unsigned C_M_AXIS_TUSER_WIDTH = 128,
    parameter int unsigned C_S_AXIS_TUSER_WIDTH = 128,
    parameter int unsigned SRC_PORT_POS = 16,
    parameter int unsigned DST_PORT_POS = 24,

    // AXI Registers Data Width
    parameter int unsigned        C_S_AXI_DATA_WIDTH = 32,
    parameter int unsigned        C_S_AXI_ADDR_WIDTH = 12,
    parameter bit          [31:0] C_BASEADDR         = 32'h00000000


) (
    // Global Ports
    input axis_aclk,
    input axis_resetn,

    // Master Stream Ports (interface to data path)
    output     [        C_M_AXIS_DATA_WIDTH - 1:0] m_axis_tdata,
    output     [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tkeep,
    output reg [         C_M_AXIS_TUSER_WIDTH-1:0] m_axis_tuser,
    output                                         m_axis_tvalid,
    input                                          m_axis_tready,
    output                                         m_axis_tlast,

    // Slave Stream Ports (interface to RX queues)
    input  [        C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata,
    input  [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tkeep,
    input  [         C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser,
    input                                      s_axis_tvalid,
    output                                     s_axis_tready,
    input                                      s_axis_tlast,

    // Slave AXI Ports
    input                               S_AXI_ACLK,
    input                               S_AXI_ARESETN,
    input  [  C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input                               S_AXI_AWVALID,
    input  [  C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input  [C_S_AXI_DATA_WIDTH/8-1 : 0] S_AXI_WSTRB,
    input                               S_AXI_WVALID,
    input                               S_AXI_BREADY,
    input  [  C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input                               S_AXI_ARVALID,
    input                               S_AXI_RREADY,
    output                              S_AXI_ARREADY,
    output [  C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output [                     1 : 0] S_AXI_RRESP,
    output                              S_AXI_RVALID,
    output                              S_AXI_WREADY,
    output [                     1 : 0] S_AXI_BRESP,
    output                              S_AXI_BVALID,
    output                              S_AXI_AWREADY
);

  // * Sketch
  // Parameters for the count-min sketch and sampling
  localparam ROWS = 4;
  localparam WIDTH = 1024;
  localparam integer SAMPLE_RATE = 128;

  reg [31:0] sketch[0:ROWS-1][0:WIDTH-1];  // Declaration of the sketch
  reg [6:0] packet_sample_count = 0;  // Packet counter for sampling
  reg [1:0] current_row = 0;  // Current row to update in the sketch
  wire [9:0] hash_result[ROWS-1:0];  // Store hash result for each row

  // Instantiate hash function units for each row
  wire [103:0] combined_input_data = {ip_protocol, ip_dst, ip_src, udp_sp, udp_dp}; // 8 + 32 + 32 + 16 + 16 = 104 bits
  generate
    genvar i;
    for (i = 0; i < ROWS; i++) begin : hash_gen
      hash #(.index(i * 10)) hash_instance (
        .input_data(combined_input_data),
        .reset(~axis_resetn),
        .clock(axis_aclk),
        .hash(hash_result[i])
      );
    end
  endgenerate

  // Sampling logic to select 1 packet per 128
  always @(posedge axis_aclk) begin
    if (!axis_resetn) begin
      packet_sample_count <= 0;
      current_row <= 0;
      for (i = 0; i < ROWS; i++) for (j = 0; j < WIDTH; j++) sketch[i][j] <= 0;
    end else if (out_pkt_begin) begin
      if (packet_sample_count == SAMPLE_RATE-1) begin
        // Update the sketch
        sketch[current_row][hash_result[current_row] % WIDTH] <= sketch[current_row][hash_result[current_row] % WIDTH] + 1;
        current_row <= (current_row + 1) % ROWS;  // Move to next row
        packet_sample_count <= 0;  // Reset counter
      end else begin
        packet_sample_count <= packet_sample_count + 1;
      end
    end
  end



  // -------- Module Registers -----------

  reg  [         `REG_ID_BITS] id_reg;
  reg  [    `REG_VERSION_BITS] version_reg;
  wire [      `REG_RESET_BITS] reset_reg;

  reg  [       `REG_FLIP_BITS] ip2cpu_flip_reg;
  wire [       `REG_FLIP_BITS] cpu2ip_flip_reg;

  reg  [      `REG_PKTIN_BITS] pktin_reg;
  wire                         pktin_reg_clear;

  reg  [     `REG_PKTOUT_BITS] pktout_reg;
  wire                         pktout_reg_clear;

  reg  [      `REG_DEBUG_BITS] ip2cpu_debug_reg;
  wire [      `REG_DEBUG_BITS] cpu2ip_debug_reg;

  reg  [    `REG_ICMPOUT_BITS] icmpout_reg;
  wire                         icmpout_reg_clear;

  reg  [  `REG_TGTIPADDR_BITS] ip2cpu_tgtipaddr_reg;
  wire [  `REG_TGTIPADDR_BITS] cpu2ip_tgtipaddr_reg;

  reg  [   `REG_TGTIPOUT_BITS] tgtipout_reg;
  wire                         tgtipout_reg_clear;

  reg  [`REG_TGTIPOUTLST_BITS] tgtipoutlst_reg;

  // -------- Internal Params ------------

  localparam int unsigned ModuleHeader = 0;
  localparam int unsigned InPacket = 1;

  // function automatic integer log2;
  //   input integer number;
  //   begin
  //     log2 = 0;
  //     while (2 ** log2 < number) log2 = log2 + 1;
  //   end
  // endfunction  // log2

  // ---------- Local Signals ------------

  wire in_fifo_nearly_full, in_fifo_empty, in_fifo_rd_en;  // For FIFO
  wire [C_M_AXIS_TUSER_WIDTH-1:0] tuser_fifo;

  assign s_axis_tready = !in_fifo_nearly_full;

  // packet is from the cpu if it is on an odd numbered port
  wire pkt_is_from_cpu = m_axis_tuser[SRC_PORT_POS+1]
                      || m_axis_tuser[SRC_PORT_POS+3]
                      || m_axis_tuser[SRC_PORT_POS+5]
                      || m_axis_tuser[SRC_PORT_POS+7];

  reg state, state_next;  // Data transmission state: ModuleHeader or InPacket

  wire                   in_pkt_end = s_axis_tlast & s_axis_tvalid & s_axis_tready;
  wire                   out_pkt_begin = m_axis_tvalid && (state == ModuleHeader);
  wire                   out_pkt_end = m_axis_tlast & m_axis_tvalid & m_axis_tready;

  wire                   clear_counters = reset_reg[0];  // Fields of Reset Register
  wire                   reset_registers = reset_reg[4];

  wire  [           7:0] ip_protocol = m_axis_tdata[184+7:184];  // Protocol filed of IP packet
  wire  [          31:0] ip_src = m_axis_tdata[208+31:208];
  wire  [          31:0] ip_dst = m_axis_tdata[240+31:240];  // Dst field of IP packet
  wire  [          15:0] udp_sp = m_axis_tdata[272+15:272];
  wire  [          15:0] udp_dp = m_axis_tdata[288+15:288];
  
  wire                   is_icmp = out_pkt_begin && (ip_protocol == 'h1);
  wire                   is_tgtip = out_pkt_begin && (ip_dst == ip2cpu_tgtipaddr_reg);

  // ------------ Modules ----------------

  fallthrough_small_fifo #(
      .WIDTH(C_M_AXIS_DATA_WIDTH + C_M_AXIS_TUSER_WIDTH + C_M_AXIS_DATA_WIDTH / 8 + 1),
      .MAX_DEPTH_BITS(2)
  ) input_fifo (  // Outputs
      .dout       ({m_axis_tlast, tuser_fifo, m_axis_tkeep, m_axis_tdata}),
      .full       (),
      .nearly_full(in_fifo_nearly_full),
      .prog_full  (),
      .empty      (in_fifo_empty),
      // Inputs
      .din        ({s_axis_tlast, s_axis_tuser, s_axis_tkeep, s_axis_tdata}),
      .wr_en      (s_axis_tvalid & ~in_fifo_nearly_full),
      .rd_en      (in_fifo_rd_en),
      .reset      (~axis_resetn),
      .clk        (axis_aclk)
  );

  // ------------- Logic ----------------

  // modify the dst port in tuser
  always_comb begin
    m_axis_tuser = tuser_fifo;
    state_next   = state;

    case (state)
      ModuleHeader: begin
        if (m_axis_tvalid) begin
          if (~|m_axis_tuser[SRC_PORT_POS+:8])  // Default: Send to MAC 0
            m_axis_tuser[DST_PORT_POS+7:DST_PORT_POS] = 8'h1;

          else if (pkt_is_from_cpu) begin
            m_axis_tuser[DST_PORT_POS+7:DST_PORT_POS] = {
              1'b0, tuser_fifo[SRC_PORT_POS+7:SRC_PORT_POS+1]
            };
          end else begin
            m_axis_tuser[DST_PORT_POS+7:DST_PORT_POS] = {
              tuser_fifo[SRC_PORT_POS+6:SRC_PORT_POS], 1'b0
            };
          end

          if (out_pkt_end) begin
            state_next = ModuleHeader;
          end else if (m_axis_tready) begin
            state_next = InPacket;
          end
        end
      end  // case: ModuleHeader
      InPacket: begin
        if (out_pkt_end) state_next = ModuleHeader;
      end
      default: ;
    endcase  // case (state)
  end  // always_comb

  always @(posedge axis_aclk) begin
    if (~axis_resetn) state <= ModuleHeader;
    else state <= state_next;
  end

  // Handle output
  assign in_fifo_rd_en = m_axis_tready && !in_fifo_empty;
  assign m_axis_tvalid = !in_fifo_empty;


  // ----------- Register ---------------

  output_port_lookup_cpu_regs #(
      .C_BASE_ADDRESS    (C_BASEADDR),
      .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
      .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
  ) opl_cpu_regs_inst (
      // General ports
      .clk                 (axis_aclk),
      .resetn              (axis_resetn),
      // AXI Lite ports
      .S_AXI_ACLK          (S_AXI_ACLK),
      .S_AXI_ARESETN       (S_AXI_ARESETN),
      .S_AXI_AWADDR        (S_AXI_AWADDR),
      .S_AXI_AWVALID       (S_AXI_AWVALID),
      .S_AXI_WDATA         (S_AXI_WDATA),
      .S_AXI_WSTRB         (S_AXI_WSTRB),
      .S_AXI_WVALID        (S_AXI_WVALID),
      .S_AXI_BREADY        (S_AXI_BREADY),
      .S_AXI_ARADDR        (S_AXI_ARADDR),
      .S_AXI_ARVALID       (S_AXI_ARVALID),
      .S_AXI_RREADY        (S_AXI_RREADY),
      .S_AXI_ARREADY       (S_AXI_ARREADY),
      .S_AXI_RDATA         (S_AXI_RDATA),
      .S_AXI_RRESP         (S_AXI_RRESP),
      .S_AXI_RVALID        (S_AXI_RVALID),
      .S_AXI_WREADY        (S_AXI_WREADY),
      .S_AXI_BRESP         (S_AXI_BRESP),
      .S_AXI_BVALID        (S_AXI_BVALID),
      .S_AXI_AWREADY       (S_AXI_AWREADY),
      // Register ports
      .id_reg              (id_reg),
      .version_reg         (version_reg),
      .reset_reg           (reset_reg),
      .ip2cpu_flip_reg     (ip2cpu_flip_reg),
      .cpu2ip_flip_reg     (cpu2ip_flip_reg),
      .ip2cpu_debug_reg    (ip2cpu_debug_reg),
      .cpu2ip_debug_reg    (cpu2ip_debug_reg),
      .pktin_reg           (pktin_reg),
      .pktin_reg_clear     (pktin_reg_clear),
      .pktout_reg          (pktout_reg),
      .pktout_reg_clear    (pktout_reg_clear),
      .icmpout_reg         (icmpout_reg),
      .icmpout_reg_clear   (icmpout_reg_clear),
      .ip2cpu_tgtipaddr_reg(ip2cpu_tgtipaddr_reg),
      .cpu2ip_tgtipaddr_reg(cpu2ip_tgtipaddr_reg),
      .tgtipout_reg        (tgtipout_reg),
      .tgtipout_reg_clear  (tgtipout_reg_clear),
      .tgtipoutlst_reg     (tgtipoutlst_reg),

      // Global Registers - user can select if to use
      .cpu_resetn_soft(),  // software reset, after cpu module
      .resetn_soft(),  // software reset to cpu module (from central reset management)
      .resetn_sync(resetn_sync)  // synchronized reset, use for better timing
  );

  // Registers Logic

  always @(posedge axis_aclk) begin
    id_reg      <= #1 `REG_ID_DEFAULT;
    version_reg <= #1 `REG_VERSION_DEFAULT;
    if (~resetn_sync | reset_registers) begin
      ip2cpu_flip_reg      <= #1 `REG_FLIP_DEFAULT;
      pktin_reg            <= #1 `REG_PKTIN_DEFAULT;
      pktout_reg           <= #1 `REG_PKTOUT_DEFAULT;
      ip2cpu_debug_reg     <= #1 `REG_DEBUG_DEFAULT;
      icmpout_reg          <= #1 `REG_ICMPOUT_DEFAULT;
      ip2cpu_tgtipaddr_reg <= #1 `REG_TGTIPADDR_DEFAULT;
      tgtipout_reg         <= #1 `REG_TGTIPOUT_DEFAULT;
      tgtipoutlst_reg      <= #1 `REG_TGTIPOUTLST_DEFAULT;
    end else begin
      ip2cpu_flip_reg <= #1 ~cpu2ip_flip_reg;
      ip2cpu_debug_reg <= #1 `REG_DEBUG_DEFAULT + cpu2ip_debug_reg;
      ip2cpu_tgtipaddr_reg <= #1 cpu2ip_tgtipaddr_reg;

      // Verible has some bugs here when disable formatter
      pktin_reg <= #1 clear_counters | pktin_reg_clear ? 'h0 : {  // Clear
      &pktin_reg[`FIELD_PKTIN] & in_pkt_end ? 1'b1 : pktin_reg[`FIELD_PKTINOVF],  // Overflow
      pktin_reg[`FIELD_PKTIN] + in_pkt_end  // Counter
      };

      pktout_reg <= #1 clear_counters | pktout_reg_clear ? 'h0 : {  // Clear
      &pktout_reg[`FIELD_PKTOUT] & out_pkt_end ? 1'b1 : pktout_reg[`FIELD_PKTOUTOVF],  // Overflow
      pktout_reg[`FIELD_PKTOUT] + out_pkt_end  // Counter
      };

      icmpout_reg <= #1 clear_counters | icmpout_reg_clear ? 'h0 : {  // Clear
      &icmpout_reg[`FIELD_ICMPOUT] & is_icmp ? 1'b1 : icmpout_reg[`FIELD_ICMPOUTOVF],  // Overflow
      icmpout_reg[`FIELD_ICMPOUT] + is_icmp  // Counter
      };

      tgtipout_reg <= #1 clear_counters | tgtipout_reg_clear ? 'h0 : {  // Clear
      &tgtipout_reg[`FIELD_TGTIPOUT] & is_tgtip ? 1'b1 : tgtipout_reg[`FIELD_TGTIPOUTOVF],
      tgtipout_reg[`FIELD_TGTIPOUT] + is_tgtip  // Counter
      };

      tgtipoutlst_reg <= #1 clear_counters ? 'h0  // Clear
      : (ip2cpu_tgtipaddr_reg != cpu2ip_tgtipaddr_reg) ? tgtipout_reg // Update on target IP change
      : tgtipoutlst_reg;

    end
  end
endmodule  // output_port_lookup
