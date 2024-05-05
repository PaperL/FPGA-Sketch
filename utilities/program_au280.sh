#! /bin/bash
source /tools/Xilinx/Vivado/2021.1/settings64.sh
lspci -d 10ee:
# PCI_DEVICE1=($(lspci -mmd 10ee:903f))
# PCI_DEVICE2=($(lspci -mmd 10ee:913f))
PCI_DEVICE1=($(lspci -mmd 10ee:500c))
PCI_DEVICE2=($(lspci -mmd 10ee:500d))
BDF1=${PCI_DEVICE1[0]}
BDF2=${PCI_DEVICE2[0]}
EXTENDED_DEVICE_BDF1=0000:$BDF1 EXTENDED_DEVICE_BDF2=0000:$BDF2 HW_DEVICE_NAME=xcu280_u55c_0 ./program_fpga.sh ./bistram.bit au280
