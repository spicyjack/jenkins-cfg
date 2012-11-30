#!/bin/sh
# other possible choices here are /bin/bash or maybe /bin/ksh

# Copyright (c)2012 by Brian Manning.
# License terms are listed at the bottom of this file
#
# Download a file if it doesn't exist on the local filesystem

### FUNCTIONS ###
check_exit_status () {
    EXIT_STATUS=$1
    DESC=$2
    OUTPUT=$3
    SCRIPT_EXIT=$EXIT_STATUS

    if [ $QUIET -ne 1 ]; then
        # check for errors from the script
        if [ $EXIT_STATUS -ne 0 ] ; then
            echo "${SCRIPTNAME}: ${DESC}"
            echo "${SCRIPTNAME}: error exit status: ${EXIT_STATUS}"
        fi
        if [ "x$OUTPUT" != "x" ]; then
            echo "${SCRIPTNAME}: ${DESC} output:"
            echo $OUTPUT
       fi
    fi
} # check_exit_status

### MAIN SCRIPT ###
# what's my name?
SCRIPTNAME=$(basename $0)
# path to the perl binary

# verbose script output by default
QUIET=0

### SCRIPT SETUP ###
# BSD's getopt is simpler than the GNU getopt; we need to detect it
OSDETECT=$(/usr/bin/env uname -s)
if [ $OSDETECT = "Darwin" ]; then
    # this is the BSD part
    TEMP=$(/usr/bin/getopt f:hl:o:qu: $* 2>/dev/null)
elif [ $OSDETECT = "Linux" ]; then
    # and this is the GNU part
    TEMP=$(/usr/bin/getopt -o f:hl:o:qu: \
        --long file:,help,log:,outdir:,quiet,url: \
        -n "${SCRIPTNAME}" -- "$@")
else
    echo "Error: Unknown OS Type.  I don't know how to call"
    echo "'getopts' correctly for this operating system.  Exiting..."
    exit 1
fi

# this script requires options; if no options were passed to it, exit with an
# error
if [ $# -eq 0 ] ; then
    echo "ERROR: this script has required options that are missing" >&2
    echo "Run '${SCRIPTNAME} --help' to see script options" >&2
    exit 1
fi

show_help () {
cat <<-EOF

    ${SCRIPTNAME} [options]

    SCRIPT OPTIONS
    -h|--help       Displays this help message
    -q|--quiet      No script output (unless an error occurs)
    -d|--deps       Quoted space separated list of dependencies
    NOTE: Long switches (a GNU extension) do not work on BSD systems (OS X)

    Example usage:
    ${SCRIPTNAME} --deps "pkg1 pkg2 pkg3 pkg4"
EOF
}

# Note the quotes around `$TEMP': they are essential!
# read in the $TEMP variable
eval set -- "$TEMP"

# read in command line options and set appropriate environment variables
# if you change the below switches to something else, make sure you change the
# getopts call(s) above
while true ; do
    case "$1" in
        -h|--help) # show the script options
            show_help
            exit 0;;
        -q|--quiet)    # don't output anything (unless there's an error)
            QUIET=1
            shift;;
        -d|--deps|--dependencies) # dependencies to check for
            DEPENDENCIES=$2;
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

if [ "x$DEPENDENCIES" = "x" ]; then
    echo "ERROR: Please pass a list dependencies to check for with --deps"
    exit 1
fi

### SCRIPT MAIN LOOP ###
if [ $QUIET -ne 1 ]; then
    echo "-> Checking dependencies..."
    echo "-> Dependency list: ${DEPENDENCIES}"
fi

# check to see if prerequisites are installed
SYSTEM_TYPE=""
if [ -e /opt/local/etc/macports/macports.conf ]; then
  SYSTEM_TYPE="MacPorts"
elif [ -e /etc/debian_version ]; then
  SYSTEM_TYPE="Debian"
fi

EXIT_STATUS=0

for DEP in $DEPENDENCIES;
do
  if [ $SYSTEM_TYPE = "Debian" ]; then
    PKG_CHECK=$(dpkg-query --show "$DEP" 2>&1)
    if [ $? -eq 1 ]; then
      EXIT_STATUS=1
      echo "- Not installed: $DEP"
    else
      echo "- Installed: $PKG_CHECK"
    fi
  fi
done

if [ $EXIT_STATUS -ne 0 ]; then
    echo "ERROR: Missing required dependencies"
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
#   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111, USA.

# vi: set filetype=sh shiftwidth=4 tabstop=4
# end of line
