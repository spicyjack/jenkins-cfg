#!/bin/bash

# Update the jenkins-config.git repo as needed

# Copyright (c)2013 by Brian Manning (brian at xaoc dot org)
# License terms are listed at the bottom of this file
#
# Impotant URLs:
# Clone:    https://github.com/spicyjack/jenkins-config.git
# Issues:   https://github.com/spicyjack/jenkins-config/issues

### MAIN SCRIPT ###
# what's my name?
SCRIPTNAME=$(basename $0)
# path to the perl binary

# verbose script output by default
QUIET=0

# default exit status
EXIT_STATUS=0

### SCRIPT SETUP ###
# source jenkins functions
#. ~/src/jenkins/config.git/scripts/common_jenkins_functions.sh
SCRIPT_FULL_PATH=$(dirname ${0})
if [ -r "${SCRIPT_FULL_PATH}/common_jenkins_functions.sh" ]; then
    # I think the 'source' function only works in bash
    #. ${MY_FULL_PATH}/common_jenkins_functions.sh
    #echo "Sourcing ${SCRIPT_FULL_PATH}/common_jenkins_functions.sh"
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

# check for the 'git' binary
GIT_BIN=$(which git)
if [ "x$GIT_BIN" = "x" ]; then
    warn "ERROR: Can't find 'git' binary file in \$PATH"
    exit 1
fi

GETOPT_SHORT="hqp:"
GETOPT_LONG="help,quiet,path:"
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
    -p|--path       Path to the Git repository directory

    Example usage:
    ${SCRIPTNAME} --path /path/to/repo.git
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
        # dependencies to check for
        -p|--path)
            GIT_REPO_PATH="$2";
            shift 2;;
        # separator between options and arguments
        --)
            shift;
            break;;
        # we shouldn't get here; die gracefully
        *)
            warn "ERROR: unknown option '$1'"
            warn "ERROR: use --help to see all script options"
            exit 1
            ;;
    esac
done

if [ "x$GIT_REPO_PATH" = "x" ]; then
    warn "ERROR: Please pass path to Git repository directory (--path)"
    exit 1
fi

if [ ! -d "$GIT_REPO_PATH" ]; then
    warn "ERROR: Git repo path ${GIT_REPO_PATH} does not exist"
    exit 1
fi

### SCRIPT MAIN LOOP ###
#show_script_header
info "Running 'git pull' in path: ${GIT_REPO_PATH}"
START_DIR=$PWD
cd $GIT_REPO_PATH
OUTPUT=$(git pull 2>&1)
EXIT_STATUS=$?
say "git: ${OUTPUT}"
cd $START_DIR

if [ $EXIT_STATUS -gt 0 ]; then
    warn "ERROR: Git repo '${GIT_REPO_PATH} was not updated"
fi

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
