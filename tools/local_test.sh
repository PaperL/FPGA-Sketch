#
# Copyright (c) 2021 University of Cambridge
# All rights reserved.
#
# This software was developed by the University of Cambridge Computer
# Laboratory under EPSRC EARL Project EP/P025374/1 alongside support 
# from Xilinx Inc.
#
# @NETFPGA_LICENSE_HEADER_START@

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
### User defined
export PYTHON_BNRY=$(which python3)
echo "     PYTHON_BNRY    :   ${PYTHON_BNRY}"

export OFO_ROOT=${HOME}/workspace/opportunistic-fpga-offload
export NFPLUS_FOLDER=${OFO_ROOT}/third_party/NetFPGA-PLUS

export BOARD_NAME=au280
export BOARD_REPO=${OFO_ROOT}/third_party/open-nic-shell/board_files

export NF_PROJECT_NAME=reference_nic

### Don't change
export VERSION=2021.1
export PROJECTS=${NFPLUS_FOLDER}/projects
export CONTRIB_PROJECTS=${NFPLUS_FOLDER}/contrib-projects
export NF_DESIGN_DIR=${NFPLUS_FOLDER}/hw/projects/${NF_PROJECT_NAME}
export NF_WORK_DIR=/tmp/${USER}
export PYTHONPATH=.:${NFPLUS_FOLDER}/tools/scripts/:${NF_DESIGN_DIR}/lib/Python:${NFPLUS_FOLDER}/tools/scripts/NFTest
export DRIVER_FOLDER=${NFPLUS_FOLDER}/lib/sw/std/driver/${DRIVER_NAME}
export APPS_FOLDER=${NFPLUS_FOLDER}/lib/sw/std/apps/${DRIVER_NAME}

board_name=`vivado -nolog -nojournal -mode batch -source get_board_parts.tcl | grep xilinx` 

export BOARD=${board_name}
export DEVICE=${device}

echo "[ok]    Vivado Version (${VERSION}) has been checked."
echo "     BOARD_NAME     :   ${BOARD_NAME}"
echo "     BOARD          :   ${BOARD}"
echo "     DEVICE         :   ${DEVICE}"
echo "     NF_PROJECT_NAME:   ${NF_PROJECT_NAME}"
echo "     NF_PROJECT_NAME:   ${NF_PROJECT_NAME}"

echo "Done..."

