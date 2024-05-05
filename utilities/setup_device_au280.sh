# *************************************************************************
#
# Copyright 2020 Xilinx, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# *************************************************************************
#! /bin/bash

set -ex

lspci -d 10ee:
# PCI_DEVICE1=($(lspci -mmd 10ee:903f))
# PCI_DEVICE2=($(lspci -mmd 10ee:913f))
PCI_DEVICE1=($(lspci -mmd 10ee:500c))
PCI_DEVICE2=($(lspci -mmd 10ee:500d))
BDF1=${PCI_DEVICE1[0]}
BDF2=${PCI_DEVICE2[0]}

device_bdf1="0000:$BDF1"
bridge_bdf1=""
device_bdf2="0000:$BDF2"
bridge_bdf2=""

if [ -e "/sys/bus/pci/devices/$device_bdf1" ]; then
    bridge_bdf1=$(basename $(dirname $(readlink "/sys/bus/pci/devices/$device_bdf1")))

    # COMMAND register: clear SERR# enable
    sudo setpci -s $bridge_bdf1 COMMAND=0000:0100
    # DevCtl register of CAP_EXP: clear ERR_FATAL (Fatal Error Reporting Enable)
    sudo setpci -s $bridge_bdf1 CAP_EXP+8.w=0000:0004
fi

if [ -e "/sys/bus/pci/devices/$device_bdf2" ]; then
    bridge_bdf2=$(basename $(dirname $(readlink "/sys/bus/pci/devices/$device_bdf2")))

    # COMMAND register: clear SERR# enable
    sudo setpci -s $bridge_bdf2 COMMAND=0000:0100
    # DevCtl register of CAP_EXP: clear ERR_FATAL (Fatal Error Reporting Enable)
    sudo setpci -s $bridge_bdf2 CAP_EXP+8.w=0000:0004
fi

echo "FPGA is ready to be programmed."
echo "Open Vivado hardware manager and do one of the following."
echo "1. Program devcie using generated bitstream."
echo "2. Add a configuration memory and program it.  After programming, boot"
echo "   from the configuration memory."
echo ""
echo "Press [c] when either 1 or 2 is completed..."
read -s -n 1 key
while [ "$key" != "c" ]; do
    echo "Press [c] when either 1 or 2 is completed..."
    read -s -n 1 key
done

echo "Doing PCI-e link re-scan..."
if [ -e "/sys/bus/pci/devices/$device_bdf1" ]; then
    echo 1 | sudo tee "/sys/bus/pci/devices/${bridge_bdf1}/${device_bdf1}/remove" > /dev/null
    echo 1 | sudo tee "/sys/bus/pci/devices/${bridge_bdf1}/rescan" > /dev/null
else
    echo 1 | sudo tee "/sys/bus/pci/rescan" > /dev/null
fi

if [ -e "/sys/bus/pci/devices/$device_bdf2" ]; then
    echo 1 | sudo tee "/sys/bus/pci/devices/${bridge_bdf2}/${device_bdf2}/remove" > /dev/null
    echo 1 | sudo tee "/sys/bus/pci/devices/${bridge_bdf2}/rescan" > /dev/null
else
    echo 1 | sudo tee "/sys/bus/pci/rescan" > /dev/null
fi

# COMMAND register: enable memory space access
sudo setpci -s $device_bdf1 COMMAND=0x02
sudo setpci -s $device_bdf2 COMMAND=0x02

echo "setup_device.sh completed"
