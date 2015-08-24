# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi


# User specific environment and startup programs

export JULIAPATH=/opt/julia
export SUBLIMEPATH=/opt/sublime
export SYNERGYPATH=/opt/synergy
export HDF5PATH=/opt/hdf5

export PYTHONPATH=/home/tom/.julia/v0.4/Qwt/src/python

export PATH=$PATH:$HOME/.local/bin:$HOME/bin:$JULIAPATH:$SUBLIMEPATH:$SYNERGYPATH/bin:$HDF5PATH/bin

# this is needed for PyCall precompilation to work
export LD_PRELOAD=/usr/lib64/libpython2.7.so.1.0
