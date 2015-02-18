#!/bin/bash

# Build the source code in an unpacked tarball

# Copyright (c)2013 by Brian Manning (brian at xaoc dot org)
# License terms are listed at the bottom of this file
#
# Impotant URLs:
# Clone:    https://github.com/spicyjack/jenkins-config.git
# Issues:   https://github.com/spicyjack/jenkins-config/issues

### MAIN SCRIPT ###
# what's my name?
SCRIPTNAME=$(basename $0)
TIME_CMD="/usr/bin/time"

# run 'make test'?
RUN_MAKE_TEST=0
# cross compile?
CROSS_COMPILE=0
# number of jobs to run (make --jobs)
NUM_OF_JOBS=4

# verbose script output by default
QUIET=0

# default exit status
EXIT_STATUS=0

# The name of the crosstool environment setup bashrc script
CROSSTOOL_ENV_FILE="crosstool-ng-env"

### SCRIPT SETUP ###
# source jenkins functions
#. ~/src/jenkins/config.git/scripts/common_jenkins_functions.sh
SCRIPT_FULL_PATH=$(dirname ${0})
if [ -r "${SCRIPT_FULL_PATH}/common_jenkins_functions.sh" ]; then
    # I think the 'source' function only works in bash
    #. ${MY_FULL_PATH}/common_jenkins_functions.sh
    echo "Sourcing ${SCRIPT_FULL_PATH}/common_jenkins_functions.sh"
    source ${SCRIPT_FULL_PATH}/common_jenkins_functions.sh
    # add paths under /usr/local
    add_usr_local_paths
else
    echo "ERROR: Can't find common_jenkins_functions.sh script!"
    echo "ERROR: Checked path: ${SCRIPT_FULL_PATH}"
fi
unset SCRIPT_FULL_PATH

#check_env_variable "$PRIVATE_STAMP_DIR" "PRIVATE_STAMP_DIR"
#check_env_variable "$PUBLIC_STAMP_DIR" "PUBLIC_STAMP_DIR"

GETOPT_SHORT="hp:qtcj:"
GETOPT_LONG="help,path:,quiet,test,cross-compile,cross,jobs:"
# sets GETOPT_TEMP
# pass in $@ unquoted so it expands, and run_getopt() will then quote it "$@"
# when it goes to re-parse script arguments
run_getopt "$GETOPT_SHORT" "$GETOPT_LONG" $@

show_help () {
cat <<-EOF

    ${SCRIPTNAME} [options]

    SCRIPT OPTIONS
    -h|--help       Displays this help message
    -q|--quiet      No script output (unless an error occurs)
    -p|--path       Path to the unpacked source code directory
    -j|--jobs       Number of 'make' jobs to run (make -j)
    -c|--cross      Build using a cross-compiler; (sources 'crosstool-ng')
    -t|--test       Run 'make test' after running 'make';
                    not all source code supports running 'make test'

    Example usage:
    ${SCRIPTNAME} --path /path/to/source/of/libfoo-0.1.2
    ${SCRIPTNAME} --cross --path /path/to/source/of/libfoo-0.1.2
EOF
}

# Note the quotes around `$GETOPT_TEMP': they are essential!
# read in the $GETOPT_TEMP variable
eval set -- "$GETOPT_TEMP"

# read in command line options and set appropriate environment variables
while true ; do
    case "$1" in
        # show the script options
        -h|--help)
            show_help
            exit 0;;
        # don't output anything (unless there's an error)
        -q|--quiet)
            QUIET=1
            shift;;
        # path to source tree
        -j|--jobs)
            NUM_OF_JOBS="$2";
            shift 2;;
        # path to source tree
        -p|--path)
            SOURCE_PATH="$2";
            shift 2;;
        # run 'make test'?
        -t|--test|--make-test)
            RUN_MAKE_TEST=1;
            shift;;
        # run 'make test'?
        -c|--cross|--cross-compile)
            CROSS_COMPILE=1;
            shift;;
        # separator between options and arguments
        --)
            shift;
            break;;
        # we shouldn't get here; die gracefully
        *)
            warn "ERROR: no handler for '$1'"
            exit 1
            ;;
    esac
done

if [ "x$SOURCE_PATH" = "x" ]; then
    warn "ERROR: Please pass a path to the unpacked source directory (--path)"
    exit 1
fi

if [ ! -d "$SOURCE_PATH" ]; then
    warn "ERROR: unpacked source path ${SOURCE_PATH} does not exist"
    exit 1
fi

### SCRIPT MAIN LOOP ###
show_script_header
if [ $CROSS_COMPILE -eq 1 ]; then
    info "Cross-compile of ${SOURCE_PATH} requested"
    info "Reading in '${CROSSTOOL_ENV_FILE}' bashrc.d script"
    if [ -e ~/.bashrc.d/${CROSSTOOL_ENV_FILE} ]; then
      source ~/.bashrc.d/${CROSSTOOL_ENV_FILE}
    else
      warn "ERROR: ${CROSSTOOL_ENV_FILE} bashrc script not found"
      exit 1
    fi
fi

if [ $RUN_MAKE_TEST -eq 0 ]; then
    info "Running 'time make; time make install'"
    info "in path: ${SOURCE_PATH}"
    MAKE_CMDS="make install"
else
    info "Running 'time make; time make test; time make install'"
    info "in path: ${SOURCE_PATH}"
    MAKE_CMDS="make test install"
fi

START_DIR=$PWD
cd $SOURCE_PATH
for MAKE_CMD in $MAKE_CMDS;
do
    if [ $MAKE_CMD = "make" ]; then
        info "Running command 'make -j ${NUM_OF_JOBS}'"
        $TIME make -j $NUM_OF_JOBS
        check_exit_status $? "make" " "
        # sets $?
        EXIT_STATUS=$?
    elif [ $MAKE_CMD = "test" ]; then
        info "Running 'make test' command"
        $TIME make test
        check_exit_status $? "make test" " "
        # sets $?
        EXIT_STATUS=$?
    elif [ $MAKE_CMD = "install" ]; then
        info "Running 'make install' command"
        $TIME make install
        check_exit_status $? "make install" " "
        # sets $?
        EXIT_STATUS=$?
    else
        warn "ERROR: Unknown make command: ${MAKE_CMD}"
        exit 1
    fi
    #MAKE_CMD="${TIME} make; ${TIME} make test; ${TIME} make install"
    if [ $EXIT_STATUS -gt 0 ]; then
        warn "ERROR: '${MAKE_CMD}' command with exit status ${EXIT_STATUS}"
        exit $EXIT_STATUS
    fi
done
cd $START_DIR

exit $EXIT_STATUS

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; version 2 dated June, 1991.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program;  if not, write to the Free Software
#   Foundation, Inc.,
#   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

# vi: set filetype=sh shiftwidth=4 tabstop=4
# end of line
