#!/bin/sh
# other possible choices here are /bin/bash or maybe /bin/ksh

# Update the jenkins-cfg.git repo as needed

# Copyright (c)2013 by Brian Manning (brian at xaoc dot org)
# License terms are listed at the bottom of this file
#
# Impotant URLs:
# Clone:    https://github.com/spicyjack/jenkins-cfg.git
# Issues:   https://github.com/spicyjack/jenkins-cfg/issues

### MAIN SCRIPT ###
# what's my name?
SCRIPTNAME=$(basename $0)
# path to the perl binary

# verbose script output by default
QUIET=0

# default exit status
EXIT_STATUS=0

### SCRIPT SETUP ###
# this script requires options; if no options were passed to it, exit with an
# error
#if [ $# -eq 0 ] ; then
#    echo "ERROR: this script has required options that are missing" >&2
#    echo "Run '${SCRIPTNAME} --help' to see script options" >&2
#    exit 1
#fi

# source jenkins functions
. ~/src/jenkins-cfg.git/scripts/common_jenkins_functions.sh

#check_env_variable "$PRIVATE_STAMP_DIR" "PRIVATE_STAMP_DIR"
check_env_variable "$PUBLIC_STAMP_DIR" "PUBLIC_STAMP_DIR"

GETOPT_SHORT="hqp:"
GETOPT_LONG="help,quiet,path:"
# sets GETOPT_TEMP
# pass in $@ unquoted so it expands, and "$@" will be used by run_getopt() to
# then re-parse the script arguments
run_getopt "$GETOPT_SHORT" "$GETOPT_LONG" $@

show_help () {
cat <<-EOF

    ${SCRIPTNAME} [options]

    SCRIPT OPTIONS
    -h|--help       Displays this help message
    -q|--quiet      No script output (unless an error occurs)
    -p|--path       Path to the 'jenkins-cfg.git' directory
    -f|--force      Force an update of jenkins-cfg, ignore stampfile

    Example usage:
    ${SCRIPTNAME} --path /path/to/jenkins-cfg.git
EOF
}

# Note the quotes around `$TEMP': they are essential!
# read in the $TEMP variable
eval set -- "$GETOPT_TEMP"

# read in command line options and set appropriate environment variables
while true ; do
    case "$1" in
        -h|--help) # show the script options
            show_help
            exit 0;;
        -q|--quiet)    # don't output anything (unless there's an error)
            QUIET=1
            shift;;
        -p|--path) # dependencies to check for
            JENKINS_CFG_PATH="$2";
            shift 2;;
        --) shift;
            break;;
        *) # we shouldn't get here; die gracefully
            echo "ERROR: unknown option '$1'" >&2
            echo "ERROR: use --help to see all script options" >&2
            exit 1
            ;;
    esac
done

echo "JENKINS_CFG_PATH is $JENKINS_CFG_PATH"
if [ "x$JENKINS_CFG_PATH" = "x" ]; then
    echo "ERROR: Please pass a path to the jenkins-cfg.git directory (--path)"
    exit 1
fi

if [ ! -d "$JENKINS_CFG_PATH" ]; then
    echo "ERROR: jenkins-cfg.git path ${JENKINS_CFG_PATH} does not exist"
    exit 1
fi

### SCRIPT MAIN LOOP ###
if [ $QUIET -ne 1 ]; then
    echo "-> Updating jenkins-cfg.git..."
    echo "-> Path: ${JENKINS_CFG_PATH}"
fi

if [ $EXIT_STATUS -ne 0 ]; then
    echo "ERROR: jenkins-cfg.git repo was not updated"
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
