#!/bin/bash

# Munge 'rpath' via the 'patchelf' binary

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

# What are we munging?  nothing by default
MUNGE_RPATH=0
UNMUNGE_RPATH=0

### SCRIPT SETUP ###
# source jenkins functions
. ~/src/jenkins/config.git/scripts/common_jenkins_functions.sh

#check_env_variable "$PRIVATE_STAMP_DIR" "PRIVATE_STAMP_DIR"
#check_env_variable "$PUBLIC_STAMP_DIR" "PUBLIC_STAMP_DIR"

GETOPT_SHORT="hqmsu"
GETOPT_LONG="help,quiet,munge,unmunge,set-path"
# sets GETOPT_TEMP
# pass in $@ unquoted so it expands, and run_getopt() will then quote it "$@"
# when it goes to re-parse script arguments
run_getopt "$GETOPT_SHORT" "$GETOPT_LONG" $@

show_help () {
cat <<-EOF

    ${SCRIPTNAME} [options]

    SCRIPT OPTIONS
    -h|--help           Displays this help message
    -q|--quiet          No script output (unless an error occurs)
    -l|--libs-path      Change RPATH in libraries in this path
    -m|--munge-path     Path to set RPATH to for libs in '--libs-path'

    Example usage:
    ${SCRIPTNAME} --libs-path /path/to/libs --munge-path /path/to/new/dir

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
        # Path to libraries that need to be munged
        -l|--libs-path)
            LIBRARIES_PATH=$2
            shift 2
        # Path to set in any libraries that are found in --libs-path
        -m|--munge-path)
            LIBRARIES_PATH=$2
            shift 2
        --) shift;
            break;;
        *) # we shouldn't get here; die gracefully
            warn "ERROR: unknown option '$1'"
            warn "ERROR: use --help to see all script options"
            exit 1
            ;;
    esac
done

### SCRIPT MAIN LOOP ###
if [ $MUNGE_RPATH -eq 0 -a $UNMUNGE_RPATH -eq 0 ]; then
    warn "ERROR: please choose either --munge or --set-path"
    warn "See script --help for more options/information"
    exit 1
fi
if [ $MUNGE_RPATH -eq 1 -a $UNMUNGE_RPATH -eq 1 ]; then
    warn "ERROR: please choose either --munge or --set-path"
    warn "See script --help for more options/information"
    exit 1
fi

# test here to see if we're munging in /output or /artifacts
show_script_header
for LIBFILE in for ${WORKSPACE}/artifacts/lib/*.so.*;
do
    info "Setting RPATH to ${WORKSPACE}/artifacts/lib for ${LIBFILE}"
    /usr/local/bin/patchelf --set-rpath ${WORKSPACE}/artifacts/lib ${LIBFILE}
    if [ $EXIT_STATUS -gt 0 ]; then
        warn "ERROR: Setting RPATH via 'patchelf' resulted in an error"
        EXIT_STATUS=1
    fi
done

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
