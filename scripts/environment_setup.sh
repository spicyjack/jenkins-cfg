#!/bin/bash

# set up the environment for testing jenkins scripts
# this could be run when you want to test the jenkins-cfg scripts by hand

if [ ! -d $HOME/workspace ]; then
    mkdir -p $HOME/workspace
fi
export WORKSPACE=$HOME/workspace
export TARBALL_DIR=$HOME/source
# XXX usually the job is going to have a specific version number set
