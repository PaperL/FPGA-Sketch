conda activate nf
source /tools/Xilinx/Vivado/2020.2/settings64.sh
source ./tools/settings.sh
cd $NFPLUS_FOLDER
./tools/scripts/nf_test.py sim --major loopback --minor minsize --dump