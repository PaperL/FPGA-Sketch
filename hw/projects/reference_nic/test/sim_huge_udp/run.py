#!/usr/bin/env python3

#
# Copyright (c) 2015 University of Cambridge
# Copyright (c) 2015 Neelakandan Manihatty Bojan, Georgina Kalogeridou
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
# as part of the DARPA MRC research programme,
# and by the University of Cambridge Computer Laboratory under EPSRC EARL Project
# EP/P025374/1 alongside support from Xilinx Inc.
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#
# Author:
#        Modified by Neelakandan Manihatty Bojan, Georgina Kalogeridou

import logging

logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from NFTest import *
from reg_defines_reference_nic import *

conn = ("../connections/conn", [])
nftest_init(sim_loop=["nf0", "nf1"], hw_config=[conn])

nftest_start()

# set parameters
SA = "aa:bb:cc:dd:ee:ff"
TTL = 64
DST_IP = "192.168.1.1"
SRC_IP = "192.168.0.1"
NUM_PKTS = 1024
num_ports = 2

pkts = []

print("Sending now: ")
totalPktLengths = [0, 0]
for i in range(NUM_PKTS):
    DA = "00:aa:bb:00:12:34"
    pkt = make_UDP_pkt(
        dst_MAC=DA,
        src_MAC=SA,
        dst_IP=DST_IP,
        src_IP=SRC_IP,
        TTL=TTL,
        dst_port=NUM_PKTS % 8,
        src_port=12345,
        pkt_len=64,
    )
    pkt.time = 1e-6
    pkts.append(pkt)

nftest_send_phy("nf0", pkts)
nftest_expect_dma("nf0", pkts)

nftest_barrier()

simReg.regDelay(1000) # Wait for packets to leave

nftest_regread_expect(NFPLUS_INPUT_ARBITER_0_PKTIN(), NUM_PKTS)
nftest_regread_expect(NFPLUS_INPUT_ARBITER_0_PKTOUT(), NUM_PKTS)
nftest_regread_expect(NFPLUS_OUTPUT_QUEUES_0_PKTSTOREDPORT2(), NUM_PKTS)
nftest_regread_expect(NFPLUS_OUTPUT_QUEUES_0_PKTREMOVEDPORT2(), NUM_PKTS)
nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_PKTIN(), NUM_PKTS)
nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_PKTOUT(), NUM_PKTS)
mres = []

nftest_finish(mres)
