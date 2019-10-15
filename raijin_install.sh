#!/bin/sh
# This script installs uwgeodynamics and badlands on raijin.nci.org.au
#
# Usage:
#  sh ./raijin_install.sh <destfolder>
#
# exit when any command fails
set -e

DATE=`date +%d%b%Y` # could be used to date checkout eg,
INSTALLPATH=`pwd`/$1
UW_DIR=$INSTALLPATH/underworld-$DATE

mkdir $INSTALLPATH

cd $INSTALLPATH
git clone https://github.com/underworldcode/underworld2.git $UW_DIR
cd $UW_DIR
git checkout master  # checkout the requested version

# setup modules
module purge
RUN_MODS='pbs dot mpi4py/3.0.2-py36-ompi3'
module load hdf5/1.10.2p petsc/3.9.4 gcc/5.2.0 mesa/11.2.2 swig/3.0.12 scons/3.0.1 $RUN_MODS
echo "*** The module list is: ***"
module list -t

# setup python environment with preinstalled packages (h5py, lavavu, pint)
export PYTHONPATH=/apps/underworld/opt/h5py/2.9.0-py36-ompi3/lib/python3.6/site-packages/h5py-2.9.0-py3.6-linux-x86_64.egg/:/apps/underworld/opt/lavavu/1.4.1_rc/:/apps/underworld/opt/pint/0.9_py36/lib/python3.6/site-packages/:$PYTHONPATH
echo "*** New PYTHONPATH: $PYTHONPATH ***"

# build and install code
cd libUnderworld
CONFIG="./configure.py  --python-dir=`python3-config --prefix` --with-debugging=0"
echo "*** The config line is: ***"
echo "$CONFIG"
echo ""

$CONFIG
./compile.py -j4
cd .. ; source updatePyPath.sh
cd $INSTALLPATH

# UWGeodynamics

pip3 install git+https://github.com/underworldcode/uwgeodynamics --prefix=$INSTALLPATH

# Badlands

git clone https://github.com/badlands-model/badlands
cd badlands/badlands/
PYTHONPATH=$INSTALLPATH/lib/python3.6/site-packages:$PYTHONPATH
python3 setup.py install --prefix=$INSTALLPATH
 
# Build module_paths.sh
cd $INSTALLPATH
touch module_paths.sh

echo "#!/bin/bash" >> module_paths.sh
echo "source $UW_DIR/updatePyPath.sh" >> module_paths.sh
echo "module purge" >> module_paths.sh
echo "module load $RUN_MODS" >> module_paths.sh
echo "" >> module_paths.sh
echo "export PYTHONPATH=$UW_DIR:$UW_DIR/glucifer:$PYTHONPATH" >> module_paths.sh
echo "" >> module_paths.sh
echo "export PATH=$PATH" >> module_paths.sh
echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> module_paths.sh
echo "export LD_PRELOAD=$OPENMPI_ROOT/lib/libmpi.so" >> module_paths.sh
echo "#####################################################################"
echo "Underworld2 built successfully at:                                   "
echo "  $UW_DIR                                                            "
echo "#####################################################################"
