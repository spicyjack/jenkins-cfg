#!/bin/sh

# Check for package dependencies needed by a library prior to compiling that
# library

# Copyright (c)2012-2013 by Brian Manning (brian at xaoc dot org)
# License terms are listed at the bottom of this file
#
# Impotant URLs:
# Clone:    https://github.com/spicyjack/jenkins-cfg.git
# Issues:   https://github.com/spicyjack/jenkins-cfg/issues

### FUNCTIONS ###
# now located in common_jenkins_functions.sh
. ~/src/jenkins-cfg.git/scripts/common_jenkins_functions.sh

### MAIN SCRIPT ###
# what's my name?
SCRIPTNAME=$(basename $0)
# path to the perl binary

# verbose script output by default
QUIET=0

### SCRIPT SETUP ###
GETOPT_SHORT="hqd:"
GETOPT_LONG="help,quiet,deps:,dependencies:"

# sets GETOPT_TEMP
# pass in $@ unquoted so it expands, and run_getopt() will then quote it
# "$@"
# when it goes to re-parse script arguments
run_getopt "$GETOPT_SHORT" "$GETOPT_LONG" $@

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

# Note the quotes around `$GETOPT_TEMP': they are essential!
# read in the $GETOPT_TEMP variable
eval set -- "$GETOPT_TEMP"

# read in command line options and set appropriate environment variables
# if you change the below switches to something else, make sure you change the
# getopts call(s) above
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
        -d|--deps|--dependencies)
            DEPENDENCIES="$2";
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

if [ "x$DEPENDENCIES" = "x" ]; then
    warn "ERROR: Please pass a list dependencies to check for with --deps"
    exit 1
fi

### SCRIPT MAIN LOOP ###
if [ $QUIET -ne 1 ]; then
    info "Checking dependencies..."
    info "Dependency list: ${DEPENDENCIES}"
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
            say "- Not installed: $DEP"
        else
            say "- Installed: $PKG_CHECK"
        fi
    elif [ $SYSTEM_TYPE "MacPorts" ]; then
        warn "MacPorts support not implemented yet :("
        exit 1
    fi
done

if [ $EXIT_STATUS -ne 0 ]; then
    warn "ERROR: Missing required dependencies"
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
