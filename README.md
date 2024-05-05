# General Sketch-based Monitoring in FPGA SmartNIC

| Thesis project code repo of Tianyuan Qiu

## Quick Start

1. Repo and toolchain
    - Vivado toolchain path: `/tools/Xilinx/Vivado/2021.1`
    - Repo path: `~/workspace/FPGA-Sketch`

2. [Optional] Check environment settings (following commands are tested in zsh)
    - Under repo: `source ./utilities/settings.sh`

3. Build / Simulation / Program
    - See `utilities` and following instructions

4. Clean
    - Run `sudo make clean` for hardware library
    - Run `make -C $NF_DESIGN_DIR/hw clean` for hardware project (reference NIC)

## Toolchain requirement

- Ubuntu 18.04
- Vivado 2021.1 (Vivado 2020.2 is available but needs some fix)
  - Download [Xilinx Application 1151 CAM](https://www.xilinx.com/member/forms/download/design-license.html?cid=154257&filename=xapp1151_Param_CAM.zip) (or search `xapp1151` on [Xilinx support website](https://www.xilinx.com/support.html). Copy the zip and update at two locations:
```
# Under NetFPGA-PLUS repo folder
$ cp xapp1151_Param_CAM.zip ./hw/lib/xilinx/cam_v1_1_0/
$ make -C ./hw/lib/xilinx/cam_v1_1_0/ update
$ cp xapp1151_Param_CAM.zip ./hw/lib/xilinx/tcam_v1_1_0/
$ make -C ./hw/lib/xilinx/tcam_v1_1_0/ update
```

## Simulation

- Run Simulation
    > Do not need compiled hw project but compiled hardware library

    > Requirements: python>3.6, scapy, cryptography. Set `PYTHON_BNRY` in `tools/settings.sh`

    > To enable VCD output, enable the commented codes at the end of [`$NF_DESIGN_DIR/hw/tcl/reference_nic_sim.tcl`]. VCD output location is `$NF_DESIGN_DIR/test/project/reference_nic.sim/sim_1/behav/xsim/dump.vcd`.
    1. Enter `cd $NFPLUS_FOLDER`
    2. Run `./tools/scripts/nf_test.py sim --major inc --minor size`

## Program and Test

1. Get the bitstream
2. [Optional] Warm reboot
3. Setup device (see OpenNIC Shell for explaination)
    > If the FPGA NIC is already deployed, shut down network device interface first with a command like `sudo ifconfig enp91s0f0 down`

    > To find the card's PCI ID(s), check the end of the result of command `lspci -nnd 10ee:`. Make sure the PCI IDs in the commands of the following 2 scripts are the same as your command result, because PCI IDs may change according to current FPGA configuration. (Use `5**c` for cold start (manufacturing(golden) image) and `9**f` for programmed shell (OpenNIC/NetFPGA/FPGA-Sketch).)
    - Run in a terminal: `bash ./utilities/setup_device_au280.sh`
        - **Keep the script running throughout the entire FPGA board programming process**

4. Run in another terminal: `bash ./utilities/program_au280.sh`
    - Check the bitstream filename in script
5. Warm reboot
6. Install driver
