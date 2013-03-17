#!/bin/bash
# other possible choices here are /bin/bash or maybe /bin/ksh

# Library of shell functions used with Jenkins job steps

# Copyright (c)2013-2013 by Brian Manning (brian at xaoc dot org)
# License terms are listed at the bottom of this file
#
# Impotant URLs:
# Clone:    https://github.com/spicyjack/jenkins-cfg.git
# Issues:   https://github.com/spicyjack/jenkins-cfg/issues

### FUNCTIONS ###
check_exit_status () {
    EXIT_STATUS="$1"
    DESC="$2"
    OUTPUT="$3"

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
    return $EXIT_STATUS
} # check_exit_status

run_getopt() {
    local GETOPT_SHORT="$1"
    local GETOPT_LONG="$2"

    # these two paths cover a majority of my test machines
    for GETOPT_CHECK in "/opt/local/bin/getopt" "/usr/bin/getopt";
    do
        if [ -x "${GETOPT_CHECK}" ]; then
            GETOPT_BIN=$GETOPT_CHECK
            break
        fi
    done

    # did we find an actual binary out of the list above?
    if [ -z "${GETOPT_BIN}" ]; then
        echo "ERROR: getopt binary not found; exiting...."
        exit 1
    fi

    # Use short options if we're using Darwin's getopt
    if [ $OSDETECT = "Darwin" -a $GETOPT_BIN != "/opt/local/bin/getopt" ]; then
        GETOPT_TEMP=$(${GETOPT_BIN} ${GETOPT_SHORT} $*)
    else
    # Use short and long options with GNU's getopt
        GETOPT_TEMP=$(${GETOPT_BIN} -o ${GETOPT_SHORT} \
            --long ${GETOPT_LONG} \
            -n "${SCRIPTNAME}" -- "$@")
    fi

    # if getopts exited with an error code, then exit the script
    #if [ $? -ne 0 -o $# -eq 0 ] ; then
    if [ $? != 0 ] ; then
        echo "Run '${SCRIPTNAME} --help' to see script options"
        exit 1
    fi
}

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
