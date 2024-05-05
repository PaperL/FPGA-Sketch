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
import random
from scapy.all import RandIP
import ipaddress

logging.getLogger("scapy.runtime").setLevel(logging.ERROR)
random.seed(123123)

from NFTest import *
from reg_defines_reference_nic import *


def ip_hex(ip_address):
    hex_ip = "".join(format(int(octet), "02X") for octet in ip_address.split("."))
    return "0x" + hex_ip


def ip_hex_reversed(ip_address):
    reversed_bytes = "".join(
        format(int(octet), "02X") for octet in ip_address.split(".")[::-1]
    )
    return reversed_bytes


def create_random_ips():
    ip_list = []
    while len(ip_list) < NUM_PKTS:
        if len(ip_list) < NUM_IP_WRONG_LAN:
            random_ip = RandIP("192.168.1.0/24")._fix()
            if random_ip != TARGET_IP:
                ip_list.append(random_ip)
        elif len(ip_list) < NUM_IP_WRONG_LAN + NUM_IP_WRONG_WAN:
            random_ip = RandIP("0.0.0.0/0")._fix()
            if random_ip != TARGET_IP:
                ip_list.append(random_ip)
        else:
            ip_list.append(TARGET_IP)
    random.shuffle(ip_list)
    return ip_list


def create_pkts(ip_list):
    pkts = []
    for i in range(NUM_PKTS):
        DA = "00:aa:bb:00:12:34"
        pkt = make_IP_pkt(
            dst_MAC=DA,
            src_MAC=SA,
            dst_IP=ip_list[i],
            src_IP=SRC_IP,
            TTL=TTL,
            pkt_len=random.randint(64, 128),
        )
        pkt.time = (i * (1e-8)) + (1e-6)
        pkts.append(pkt)
    return pkts


def append_ip_dst_log(ip_list):
    # targetIpHex = [
    #     int.from_bytes(ipaddress.ip_address(ip_str).packed) for ip_str in random_ips
    # ]
    # for i in range(len(random_ips)):
    #     output_str = str(
    #         random_ips[i].rjust(20) + "\t" + "0x{:08X}".format(targetIpHex[i]) + "\n"
    #     )
    #     file.write(output_str)
    with open("ip_dst.log", "a") as file:  # Find output under the `test` folder
        targetIpHexReversed = int(ip_hex_reversed(TARGET_IP), 16)
        file.write("\n\n\n")
        file.write("Target IP             : " + TARGET_IP + "\n")
        file.write("Target IP signal (int): " + str(targetIpHexReversed) + "\n")
        file.write("Target IP (hex)       : " + ip_hex(TARGET_IP) + "\n")
        file.write("Target IP signal (hex): " + ip_hex_reversed(TARGET_IP) + "\n")
        file.write("\n")
        file.write("              DST_IP	  IP_HEX  	IP_HEX_SIGNAL\n")
        for ip_str in ip_list:
            output_str = "\t".join(
                [ip_str.rjust(20), ip_hex(ip_str), ip_hex_reversed(ip_str)]
            )
            file.write(output_str + "\n")


conn = ("../connections/conn", [])
nftest_init(sim_loop=["nf0", "nf1"], hw_config=[conn])
nftest_start()

# set parameters
SA = "aa:bb:cc:dd:ee:ff"
DA = "00:cc:aa:23:11:02"
SRC_IP = "192.168.0.1"
TTL = 64

TARGET_IP = "192.168.1.1"
NUM_IP_CORRECT = 17
NUM_IP_WRONG_LAN = 7
NUM_IP_WRONG_WAN = 11
NUM_PKTS = NUM_IP_CORRECT + NUM_IP_WRONG_LAN + NUM_IP_WRONG_WAN


# Part 1
random_ips = create_random_ips()
append_ip_dst_log(random_ips)
pkts = create_pkts(random_ips)

print("Setting target IP1")
targetIpHexReversed = int(ip_hex_reversed(TARGET_IP), 16)
nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_TGTIPADDR(), targetIpHexReversed)
print("Sending first part: ")
nftest_send_phy("nf0", pkts)
nftest_expect_dma("nf0", pkts)
nftest_barrier()
nftest_regread_expect(NFPLUS_INPUT_ARBITER_0_PKTIN(), NUM_PKTS)
nftest_regread_expect(NFPLUS_INPUT_ARBITER_0_PKTOUT(), NUM_PKTS)
nftest_regread_expect(NFPLUS_OUTPUT_QUEUES_0_PKTSTOREDPORT2(), NUM_PKTS)
nftest_regread_expect(NFPLUS_OUTPUT_QUEUES_0_PKTREMOVEDPORT2(), NUM_PKTS)
nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_PKTIN(), NUM_PKTS)
nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_PKTOUT(), NUM_PKTS)
nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_ICMPOUT(), 0)
# Do not read tgtipout because it will be cleared on read

# Part 2
TARGET_IP = "192.168.1.2"
random_ips = create_random_ips()
append_ip_dst_log(random_ips)
pkts = create_pkts(random_ips)

print("Setting target IP2")
targetIpHexReversed = int(ip_hex_reversed(TARGET_IP), 16)
nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_TGTIPADDR(), targetIpHexReversed)
print("Sending second part: ")
nftest_send_phy("nf0", pkts)
nftest_expect_dma("nf0", pkts)
nftest_barrier()

# Result verification
nftest_regread_expect(NFPLUS_INPUT_ARBITER_0_PKTIN(), NUM_PKTS)
nftest_regread_expect(NFPLUS_INPUT_ARBITER_0_PKTOUT(), NUM_PKTS)
nftest_regread_expect(NFPLUS_OUTPUT_QUEUES_0_PKTSTOREDPORT2(), NUM_PKTS)
nftest_regread_expect(NFPLUS_OUTPUT_QUEUES_0_PKTREMOVEDPORT2(), NUM_PKTS)
nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_PKTIN(), NUM_PKTS)
nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_PKTOUT(), NUM_PKTS)
nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_ICMPOUT(), 0)
nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_TGTIPOUT(), NUM_IP_CORRECT * 2)
nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_TGTIPOUTLST(), NUM_IP_CORRECT)
nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_TGTIPOUT(), 0)
mres = []

nftest_finish(mres)
