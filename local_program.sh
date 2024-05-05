source /tools/Xilinx/Vivado/2020.2/settings64.sh
source ./tools/settings.sh

cd $NF_DESIGN_DIR/bitfiles
# xsdb
# connect
# fpga -f <name of bitfile .bit>
# exit

cd $NFPLUS_FOLDER/sw/driver
make
sudo insmod open-nic-driver/onic.ko

cd $NFPLUS_FOLDER/sw/app
make