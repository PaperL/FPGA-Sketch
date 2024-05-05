set -x
sudo make clean
sudo make -C ./hw/projects/reference_nic/hw clean
source /tools/Xilinx/Vivado/2021.1/settings64.sh
    source ./tools/settings.sh
cd $NFPLUS_FOLDER
make
make -C $NF_DESIGN_DIR/hw
