#!/bin/bash

# Unpack artifacts from previous build(s); note, Jenkins needs to be told to
# copy artifacts from one job to another, this script just unpacks the copied
# artifacts to the $WORKSPACE/artifacts directory

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
. ~/src/jenkins/config.git/scripts/common_jenkins_functions.sh

#check_env_variable "$PRIVATE_STAMP_DIR" "PRIVATE_STAMP_DIR"
#check_env_variable "$PUBLIC_STAMP_DIR" "PUBLIC_STAMP_DIR"

GETOPT_SHORT="hq"
GETOPT_LONG="help,quiet"
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

    Example usage:
    ${SCRIPTNAME} -- foo bar

    Note: artifact files should be named 'library.artifact.tar.xz', the
    library name 'library' is the only part of the artifact file that should
    be passed in to this script.

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
    info "Unpacking and configuring $# tarball(s) in $WORKSPACE/artifacts"
    cd $WORKSPACE
    # remove the old artifacts directory
    if [ -d $WORKSPACE/artifacts ]; then
        info "Deleting old artifacts directory..."
        rm -rvf $WORKSPACE/artifacts
    fi
    # make a new directory
    info "Creating new artifacts directory..."
    mkdir $WORKSPACE/artifacts
    cd $WORKSPACE/artifacts

    # loop across the list of artifacts passed in on the command line
    # Jenkins puts them into the $WORKSPACE by default
    while [ $# -gt 0 ];
    do
        ARTIFACT=$1
        if [ -r "${WORKSPACE}/${ARTIFACT}.artifact.tar.xz" ]; then
            info "Unpacking artifact '$ARTIFACT' (${ARTIFACT}.artifact.tar.xz)"
            tar -Jxvf ../${ARTIFACT}.artifact.tar.xz
        else
            warn "ERROR: ${WORKSPACE}/${ARTIFACT}.artifact.tar.xz not found"
            EXIT_STATUS=1
        fi
        # pop the file off of the arg stack
        shift
    done

    # do some file munging
    find "$PWD" -print0 | egrep --null-data --null '.la$|.pc$' \
            | sort -z | while IFS= read -d $'\0' MUNGE_FILE;
    do
        SHORT_MUNGE_FILE=$(echo ${MUNGE_FILE} | sed "{s!${WORKSPACE}!!;s!^/!!}")
            # '^prefix=' is in pkgconfig '*.pc' files
            SED_EXPR="s!:PREFIX:!prefix=${WORKSPACE}/artifacts!g"
            # generic sed to catch anything with 'output' in it's path
            SED_EXPR="${SED_EXPR}; s!:OUTPUT:!${WORKSPACE}/artifacts!g"
            # generic sed to catch anything with 'artifacts' in it's path
            SED_EXPR="${SED_EXPR}; s!:ARTIFACTS:!${WORKSPACE}/artifacts!g"
            # wrap all of the above sed expressions inside curly brackets
            SED_EXPR="{$SED_EXPR}"
            info "Munging libtool file: ${SHORT_MUNGE_FILE}"
            info "'sed' expression is: ${SED_EXPR}"
            sed -i "${SED_EXPR}" "${MUNGE_FILE}"
            # FIXME check_exit_status here
    done
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
