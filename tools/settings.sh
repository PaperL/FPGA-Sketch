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
export PYTHON_BNRY=$(command -v python3)

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
export NF_WORK_DIR=${NFPLUS_FOLDER}/local_test
export PYTHONPATH=.:${NFPLUS_FOLDER}/tools/scripts/:${NF_DESIGN_DIR}/lib/Python:${NFPLUS_FOLDER}/tools/scripts/NFTest
export DRIVER_FOLDER=${NFPLUS_FOLDER}/lib/sw/std/driver/${DRIVER_NAME}
export APPS_FOLDER=${NFPLUS_FOLDER}/lib/sw/std/apps/${DRIVER_NAME}


# Check and import Xilinx Shell
# create_symlink() {
#     local source_dir="$1"
#     local target_link="$2"

#     if [ -d "$source_dir" ]; then
#         if [ -L "$target_link" ]; then
#             rm "$target_link"
#         fi
#         ln -s "$source_dir" "$target_link"
#     else
#         echo "Error: $source_dir is not found."
#         return -1
#     fi
# }
# create_symlink "${OFO_ROOT}/third_party/open-nic-shell" "${NFPLUS_FOLDER}/hw/lib/xilinx/xilinx_shell_v1_0_0/open-nic-shell" || return -1
# create_symlink "${OFO_ROOT}/third_party/open-nic-driver" "${NFPLUS_FOLDER}/sw/driver/open-nic-driver" || return -1
# echo "[ok]    Xilinx shell and driver are imported with symbolic links."

# Check python3
[ -z "$PYTHON_BNRY" ] && echo "Error: python3 is missing." && exit 1
echo "     PYTHON_BNRY    :   ${PYTHON_BNRY}"

# Check NetFPGA, test and target project folders
if [ ! -d ${NFPLUS_FOLDER} ] ; then
	echo "Error: ${NFPLUS_FOLDER} is not found."
	return -1
fi
if [ ! -d "$NF_WORK_DIR" ]; then
	mkdir -p "$NF_WORK_DIR"
fi
if [ ! -d ${NF_DESIGN_DIR} ] ; then
	echo "Error: ${NF_PROJECT_NAME} cannot be found."
	return -1
fi
echo "[ok]    Work folders have been checked."
echo "     NFPLUS_FOLDER  :   ${NFPLUS_FOLDER}"
echo "     NF_WORK_DIR (for test): ${NF_WORK_DIR}"
echo "     NF_PROJECT_NAME:   ${NF_PROJECT_NAME}"
echo "     NF_DESIGN_DIR  :   ${NF_DESIGN_DIR}"

# Check board files
if [ ${BOARD_NAME} != "au280" -a \
     ${BOARD_NAME} != "au250" -a \
     ${BOARD_NAME} != "au200" -a \
     ${BOARD_NAME} != "au50"  -a \
     ${BOARD_NAME} != "vcu1525" ] ; then 
	echo "Error: ${BOARD_NAME} is not supported."
	echo "    Supported boards are au280, au250, au200, au50, and vcu1525."
	return -1
else
	board_name=`vivado -nolog -nojournal -mode batch -source ${NFPLUS_FOLDER}/tools/get_board_parts.tcl | grep xilinx`
	if [ ${BOARD_NAME} = "au280" ] ; then
		device="xcu280-fsvh2892-2L-e"
	elif [ ${BOARD_NAME} = "au250" ] ; then
		device="xcu250-figd2104-2L-e"
	elif [ ${BOARD_NAME} = "au200" ] ; then
		device="xcu200-fsgd2104-2-e"
	elif [ ${BOARD_NAME} = "au50" ] ; then
		device="xcu50-fsvh2104-2-e"
	elif [ ${BOARD_NAME} = "vcu1525" ] ; then
		device="xcvu9p-fsgd2104-2L-e"
	fi
fi
export BOARD=${board_name}
export DEVICE=${device}
[ ! -d "$BOARD_REPO" ] && echo "Warning: user defined board files repo does not exist."
[ -z "$BOARD" ] && echo "Error: cannot find board part." && exit 1
echo "[ok]    Board files of (${BOARD_NAME}) have been checked."
echo "     BOARD_NAME     :   ${BOARD_NAME}"
echo "     BOARD_REPO     :   ${BOARD_REPO}"
echo "     BOARD          :   ${BOARD}"
echo "     DEVICE         :   ${DEVICE}"

# Check Vivado version
vivado_version=`echo $XILINX_VIVADO | awk -F "/" 'NF>1{print $NF}'`
if [ -z ${vivado_version} ]; then
	echo "Error: please source vivado scripts. e.g. /tools/Xilinx/Vivado/2021.1/settings64.sh"
	return -1
fi
if [[ $vivado_version != $VERSION* ]]; then
	echo "Error: you don't have proper Vivado version (${VERSION})."
	return -1
fi
echo "[ok]    Vivado Version (${VERSION}) has been checked."

echo "Done..."

