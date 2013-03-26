#!/bin/sh

# Archive the output of a source code build

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
# source jenkins functions
. ~/src/jenkins-cfg.git/scripts/common_jenkins_functions.sh

#check_env_variable "$PRIVATE_STAMP_DIR" "PRIVATE_STAMP_DIR"
#check_env_variable "$PUBLIC_STAMP_DIR" "PUBLIC_STAMP_DIR"

GETOPT_SHORT="hqn:s:o:"
GETOPT_LONG="help,quiet,name:,source-version:,version:,output:,output-dir:"
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
    -n|--name           Name of the archive tarball to create
    -s|--source-version Version of the source code that was compiled
    -o|--output         Write tarball to this directory (usually \$WORKSPACE)

    Example usage:
    ${SCRIPTNAME} --output=\${WORKSPACE} \\
        --name=<source package name> --source-version="1.2.3"

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
        # source package name
        -n|--name) 
            SOURCE_NAME="$2";
            shift 2;;
        # source package version
        -s|--source-version|--version) 
            SOURCE_VERSION="$2";
            shift 2;;
        # configure args y
        -o|--output|--output-dir)
            OUTPUT_DIR="$2";
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

if [ "x$SOURCE_NAME" = "x" ]; then
    warn "ERROR: Please pass the name of the source package (--source)"
    exit 1
fi

if [ "x$OUTPUT_DIR" = "x" ]; then
    warn "ERROR: Please pass the path to the output directory (--output)"
    exit 1
fi

### SCRIPT MAIN LOOP ###
show_script_header
# sets ARTIFACT_TIMESTAMP
generate_artifact_timestamp
if [ -d "${OUTPUT_DIR}/output" ]; then
    info "Creating archive file ${OUTPUT_DIR}/${SOURCE_NAME}.artifact.tar.xz"
    START_DIR=$PWD
    cd ${OUTPUT_DIR}/output
    # create a stampfile
    touch ${OUTPUT_DIR}/${SOURCE_NAME}-${SOURCE_VERSION}.${ARTIFACT_TIMESTAMP}
    # create the build artifact
    TAR_CMD="tar -Jcvf ${OUTPUT_DIR}/${SOURCE_NAME}.artifact.tar.xz ."
    eval $TAR_CMD
    check_exit_status $? "$TAR_CMD" " "
    EXIT_STATUS=$?
    cd $START_DIR
else
    warn "ERROR: source build directory ${OUTPUT_DIR}/output missing!"
    EXIT_STATUS=1
fi

if [ $EXIT_STATUS -gt 0 ]; then
    warn "ERROR: archive creation command exited with an error!"
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
