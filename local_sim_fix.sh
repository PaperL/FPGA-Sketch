conda activate nff
source /tools/Xilinx/Vivado/2021.1/settings64.sh
source ./tools/settings.sh
cd $NFPLUS_FOLDER
./tools/scripts/nf_test.py sim --major few --minor minsize