#!/bin/bash

# Munge files like 'sdl-config' and 'libmikmod-config', setting the path to
# the current artifacts directory

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
MUNGE_SDL=0
UNMUNGE_SDL=0

### SCRIPT SETUP ###
# source jenkins functions
. ~/src/jenkins/config.git/scripts/common_jenkins_functions.sh

#check_env_variable "$PRIVATE_STAMP_DIR" "PRIVATE_STAMP_DIR"
#check_env_variable "$PUBLIC_STAMP_DIR" "PUBLIC_STAMP_DIR"

GETOPT_SHORT="hqf:mu"
GETOPT_LONG="help,quiet,file:,munge,unmunge"
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
    -f|--file           Filename of the file to munge/unmunge
    -m|--munge          Change paths in '--file' to ':ARTIFACTS:'
    -u|--unmunge        Change ':ARTIFACTS:' in '--file' to artifacts path

    Example usage:
    ${SCRIPTNAME} --munge --file /path/to/sdl-config
    ${SCRIPTNAME} --unmunge --file /path/to/libmikmod-config

    Note: The path to the lib configs to munge/unmunge is assumed by this
    script to be located at \$WORKSPACE/artifacts.

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
        # Munge '$WORKSPACE/output/bin/sdl-config'
        -f|--file)
            MUNGE_FILE="$2"
            shift 2;;
        # Munge '$WORKSPACE/output/bin/sdl-config'
        -m|--munge)
            MUNGE_SDL=1
            shift;;
        # Unmunge '$WORKSPACE/artifacts/bin/sdl-config'
        -u|--unmunge)
            UNMUNGE_SDL=1
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
MUNGE_CONFUSION=0
if [ $MUNGE_SDL -eq 0 -a $UNMUNGE_SDL -eq 0 ]; then
    MUNGE_CONFUSION=1
fi
if [ $MUNGE_SDL -eq 1 -a $UNMUNGE_SDL -eq 1 ]; then
    MUNGE_CONFUSION=1
fi
if [ $MUNGE_CONFUSION -eq 1 ]; then
    warn "ERROR: please choose either --munge or --unmunge"
    warn "See script --help for more options/information"
    exit 1
fi

# test here to see if we're munging in /output or /artifacts
show_script_header
if [ $MUNGE_SDL -eq 1 ]; then
    MUNGE_TARGET="${WORKSPACE}/output/bin/${MUNGE_FILE}"
    #SHORT_FILE=$(echo ${MUNGE_FILE} | sed "{s!${WORKSPACE}!!;s!^/!!}")
    info "Munging '${MUNGE_FILE}' (\$WORKSPACE/output -> :ARTIFACTS:)"
    SED_EXPR="s!${WORKSPACE}/output!:ARTIFACTS:!g"
    info "'sed' expression is: ${SED_EXPR}"
    sed -i "${SED_EXPR}" "${MUNGE_TARGET}"
elif [ $UNMUNGE_SDL -eq 1 ]; then
    MUNGE_TARGET="${WORKSPACE}/artifacts/bin/${MUNGE_FILE}"
    #SHORT_FILE=$(echo ${MUNGE_FILE} | sed "{s!${WORKSPACE}!!;s!^/!!}")
    info "Un-munging '${MUNGE_FILE}' (:ARTIFACTS: -> \$WORKSPACE/artifacts"
    SED_EXPR="s!:ARTIFACTS:!${WORKSPACE}/artifacts!g"
    info "'sed' expression is: ${SED_EXPR}"
    sed -i "${SED_EXPR}" "${MUNGE_TARGET}"
else
    warn "ERROR: can't decide to munge or unmunge 'sdl-config'"
    warn "ERROR: this block of code should not have been reached"
    EXIT_STATUS=1
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
