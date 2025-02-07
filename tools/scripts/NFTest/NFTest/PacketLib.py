#!/usr/bin/env python3

#
# Copyright (c) 2015 University of Cambridge
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory 
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
# as part of the DARPA MRC research programme.
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

import sys
import os
from random import randint
from random import seed
from scapy.all import Raw, RandString
import scapy.all as scapy

############################
# Function: make_MAC_hdr
# Keyword Arguments: src_MAC, dst_MAC, EtherType
# Description: creates and returns a scapy Ether layer
#              if keyword arguments are not specified, scapy defaults are used
############################
def make_MAC_hdr(src_MAC = None, dst_MAC = None, EtherType = None, **kwargs):
    hdr = scapy.Ether()
    if src_MAC:
        hdr.src = src_MAC
    if dst_MAC:
        hdr.dst = dst_MAC
    if EtherType:
        hdr.type = EtherType
    return hdr

############################
# Function: make_IP_hdr
# Keyword Arguments: src_IP, dst_IP, TTL
# Description: creates and returns a scapy Ether layer
#              if keyword arguments are not specified, scapy defaults are used
############################
def make_IP_hdr(src_IP = None, dst_IP = None, TTL = None, **kwargs):
    hdr = scapy.IP()
    if src_IP:
        hdr[scapy.IP].src = src_IP
    if dst_IP:
        hdr[scapy.IP].dst = dst_IP
    if TTL:
        hdr[scapy.IP].ttl = TTL
    return hdr

############################
# Function: make_ARP_hdr
# Keyword Arguments: src_IP, dst_IP, TTL
# Description: creates and returns a scapy ARP layer
#              if keyword arguments are not specified, scapy defaults are used
############################
def make_ARP_hdr(op = None, src_MAC = None, dst_MAC = None, src_IP = None, dst_IP = None, **kwargs):
    hdr = scapy.ARP()
    if op:
        hdr.op = op
    if src_MAC:
        hdr.hwsrc = src_MAC
    if dst_MAC:
        hdr.hwdst = dst_MAC
    if src_IP:
        hdr.psrc = src_IP
    if dst_IP:
        hdr.pdst = dst_IP
    return hdr

############################
# Function: make_VLAN_hdr
# Keyword Arguments: vlan, id, priority
# Description: creates and returns a scapy VLAN layer
#              if keyword arguments are not specified, scapy defaults are used
############################

def make_VLAN_hdr(vlan = None, id = None, prio = None, **kwargs):
    hdr = scapy.Dot1Q()
    if vlan:
        hdr.vlan = vlan
    if id:
        hdr.id = id
    if prio:
        hdr.prio = prio
    return hdr

############################
# Function: make_ICMP_hdr
# Keyword Arguments: vlan, id, priority
# Description: creates and returns a scapy VLAN layer
#              if keyword arguments are not specified, scapy defaults are used
############################

def make_ICMP_hdr(type = None, id = None, seq = None, **kwargs):
    hdr = scapy.ICMP()
    if type:
        hdr.type = type
    if id:
        hdr.id = id
    if seq:
        hdr.seq = seq
    return hdr

############################
# Function: make_IP_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#                    src_IP, dst_IP, TTL
#                    pkt_len
# Description: creates and returns a complete IP packet of length pkt_len
############################

def make_IP_pkt(pkt_len = 60, **kwargs):
    if pkt_len < 60:
        pkt_len = 60
    pkt = make_MAC_hdr(**kwargs)/make_IP_hdr(**kwargs)/generate_load(pkt_len - 34)
    return pkt

############################
# Function: make_UDP_hdr
# Keyword Arguments: src_port, dst_port, len
# Description: creates and returns a scapy UDP layer 
#              if keyword arguments are not specified, scapy defaults are used
############################

def make_UDP_hdr(src_port = None, dst_port = None, udp_len = None, **kwargs):
    hdr = scapy.UDP()
    if src_port:
        hdr.sport = src_port
    if dst_port:
        hdr.dport = dst_port
    if udp_len:
        hdr.len = udp_len
    return hdr

############################
# Function: make_UDP_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#                    src_IP, dst_IP, TTL
#                    src_port, dst_port, len
#                    pkt_len
# Description: creates and returns a complete UDP packet of length pkt_len
############################

def make_UDP_pkt(pkt_len = 60, **kwargs):
    if pkt_len < 60:
        pkt_len = 60
    pkt = make_MAC_hdr(**kwargs)/make_IP_hdr(**kwargs)/make_UDP_hdr(udp_len=pkt_len-42, **kwargs)/generate_load(pkt_len - 42) # Total header length is 42 for MAC + IP + UDP
    return pkt

############################
# Function: make_VLAN_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#                    src_IP, dst_IP, TTL
#                    pkt_len
# Description: creates and returns a complete IP packet of length pkt_len with VLAN headers
############################

def make_VLAN_pkt(pkt_len = 60, **kwargs):
    if pkt_len < 60:
        pkt_len = 60
    pkt = make_MAC_hdr(**kwargs)/make_VLAN_hdr(**kwargs)/make_IP_hdr(**kwargs)/generate_load(pkt_len - 34)
    return pkt


############################
# Function: make_ICMP_reply_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#                    src_IP, dst_IP, TTL
# Description: creates and returns a complete ICMP reply packet
############################
def make_ICMP_reply_pkt(data = None, **kwargs):
    pkt = make_MAC_hdr(**kwargs)/make_IP_hdr(**kwargs)/scapy.ICMP(type="echo-reply")
    if data:
        pkt = pkt/data
    else:
        pkt = pkt/("\x00"*56)
    return pkt

############################
# Function: make_ICMP_request_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#                    src_IP, dst_IP, TTL
# Description: creates and returns a complete ICMP request packet
############################
def make_ICMP_request_pkt(pkt_len = 90, **kwargs):
    pkt_len = 60 if pkt_len<60 else pkt_len
    pkt = make_MAC_hdr(**kwargs)/make_IP_hdr(**kwargs)/make_ICMP_hdr(**kwargs, type="echo-request")/generate_load(pkt_len - 34)
    return pkt

############################
# Function: make_ICMP_ttl_exceed_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#                    src_IP, dst_IP, TTL
# Description: creates and returns a complete ICMP reply packet
############################
def make_ICMP_ttl_exceed_pkt(**kwargs):
    pkt = make_MAC_hdr(**kwargs)/make_IP_hdr(**kwargs)/scapy.ICMP(type=11, code=0)
    return pkt

############################
# Function: make_ICMP_host_unreach_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#                    src_IP, dst_IP, TTL
# Description: creates and returns a complete ICMP reply packet
############################
def make_ICMP_host_unreach_pkt(**kwargs):
    pkt = make_MAC_hdr(**kwargs)/make_IP_hdr(**kwargs)/scapy.ICMP(type=3, code=0)
    return pkt

############################
# Function: make_ARP_request_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#                    src_IP, dst_IP
# Description: creates and returns a complete ICMP reply packet
############################
def make_ARP_request_pkt(**kwargs):
    pkt = make_MAC_hdr(**kwargs)/make_ARP_hdr(op="who-has", **kwargs)/("\x00"*18)
    return pkt

############################
# Function: make_ARP_reply_pkt
# Keyword Arguments: src_MAC, dst_MAC, EtherType
#
# Description: creates and returns a complete ARP reply packet
############################
def make_ARP_reply_pkt(**kwargs):
    pkt = make_MAC_hdr(**kwargs)/make_ARP_hdr(op="is-at", **kwargs)/("\x00"*18)
    return pkt

############################
# Function: generate_load
# Keyword Arguments: length
# Description: creates and returns a payload of the specified length
############################
def generate_load(length):
    return Raw('\x00' * length)
    # return Raw(RandString(length))

############################
# Function: set_seed
# Description: sets the seed for the random number generator if specified
#              enables reproducibility in tests
############################
def set_seed():
    global SEED
    if '--seed' in sys.argv:
            SEED = int(sys.argv[sys.argv.index('--seed')+1])
    else:
        SEED = hash(os.urandom(32))
    seed(SEED)

############################
# Function: print_seed
# Description: returns the seed used by the random number generator
############################
def print_seed():
    f = open('./seed', 'w')
    f.write(str(SEED))
    f.close()

set_seed()
print_seed()
