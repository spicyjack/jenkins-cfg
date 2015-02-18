#!/bin/bash

# Script to locate and run functions inside of the
# `common_jenkins_functions.sh` script

# First, locate the 'common_jenkins_functions.sh' file, based on the location
# of this script

MY_FULL_PATH=$(dirname ${0})
QUIET=0
echo "dirname is: ${MY_FULL_PATH}"

if [ -r "${MY_FULL_PATH}/common_jenkins_functions.sh" ]; then
    # I think the 'source' function only works in bash
    #. ${MY_FULL_PATH}/common_jenkins_functions.sh
    echo "Sourcing ${MY_FULL_PATH}/common_jenkins_functions.sh"
    source ${MY_FULL_PATH}/common_jenkins_functions.sh
    say "This is a test of say() from common_jenkins_functions.sh"
    QUIET=1
    echo "Testing QUIET=1"
    say "This should not print"
    echo "Testing complete!"
else
    echo "ERROR: 'common_jenkins_functions.sh' script not found!"
    exit 1
fi
