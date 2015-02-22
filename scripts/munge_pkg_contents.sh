#!/bin/bash

# After Debian packages have been unpacked in the $WORKSPACE/artifacts
# directory, munge various files inside of them

# Copyright (c)2015 by Brian Manning (brian at xaoc dot org)
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

# don't delete artifact files by default after unpacking
MUNGE_DIR=

# default exit status
EXIT_STATUS=0

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

# munge the 'prefix=' parameter found in files that are passed in
munge_prefix () {
    local MUNGE_FILE="$1"
    # '^prefix=' is in pkgconfig '*.pc' files and files like 'sdl-config',
    # 'libmikmod-config', etc.
    SED_EXPR="s!^prefix=/usr!prefix=${WORKSPACE}/artifacts/usr!g"
    info "Munging file: '${MUNGE_FILE}'"
    info "('sed' expression: ${SED_EXPR})"
    sed -i "${SED_EXPR}" "${MUNGE_FILE}"
    check_exit_status $? "sed -i ${SED_EXPR} ${munge_prefix}"
    # $? is now the result of check_exit_status
    if [ $? -eq 0 ]; then
        info "Munge successful"
    else
        warn "Munge unsuccessful!"
    fi
}

GETOPT_SHORT="hq"
GETOPT_LONG="help,quiet"
# from 'common_jenknis_functions.sh'; sets GETOPT_TEMP
# pass in $@ unquoted so it expands, and run_getopt() will then quote it "$@"
# when it goes to re-parse script arguments
run_getopt "$GETOPT_SHORT" "$GETOPT_LONG" $@

show_help () {
cat <<-EOF

    ${SCRIPTNAME} [options]

    SCRIPT OPTIONS
    -h|--help           Displays this help message
    -q|--quiet          No script output (unless an error occurs)

    Example usage:

    # Munge files passed in as arguments
    ${SCRIPTNAME} -- /path/to/dir /path/to/file.pc

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
        -p|--path)
            MUNGE_DEST_PATH="$2";
            shift 2;;
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
if [ $# -gt 0 ]; then
    show_script_header

    # loop across the list of artifacts passed in on the command line
    # Jenkins puts them into the $WORKSPACE by default
    while [ $# -gt 0 ];
    do
        MUNGE_ARG=$1
        if [ -d "${MUNGE_ARG}" ]; then
            info "Munging files in '${MUNGE_ARG}'"
            find "${MUNGE_ARG}" -print0 | egrep --null-data --null '.la$|.pc$' \
                    | sort -z | while IFS= read -d $'\0' MUNGE_FILE;
            do
                munge_prefix $MUNGE_FILE
            done

        elif [ -f "${MUNGE_ARG}" ]; then
            munge_prefix $MUNGE_ARG
        else
            warn "${MUNGE_ARG} is not a file or directory"
            EXIT_STATUS=1
        fi
        # pop the file off of the arg stack
        shift
    done
else
    warn "ERROR: no files passed in to script"
    warn "ERROR: use --help to see all script options"
    exit 1
fi

if [ $EXIT_STATUS -gt 0 ]; then
    warn "ERROR: Unpacking artifacts resulted in an error"
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
