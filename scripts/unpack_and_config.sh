#!/bin/sh

# Unpack a source tarball and run ./configure on it

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

GETOPT_SHORT="hqp:s:t:"
GETOPT_LONG="help,quiet,prefix:,sourcedir:,tarball:"
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
    -p|--prefix         Prefix to install path; usually \$WORKSPACE/output
    -c|--config-args    Arguments to pass to './configure'
    -t|--tarball        Filename of tarball to download and/or unpack

    Example usage:
    ${SCRIPTNAME} --prefix=\${WORKSPACE}/output \\
    --config-args="--arg1=foo --arg2=bar" \\
    --tarball=\$TARBALL_DIR/tarball_name-version.tar.gz \\

EOF
}

# Note the quotes around `$GETOPT_TEMP': they are essential!
# read in the $GETOPT_TEMP variable
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
        # prefix path
        -p|--prefix|--path) 
            PREFIX_PATH="$2";
            shift 2;;
        # configure args y
        -c|--config-args|--config|--configargs)
            CONFIG_ARGS="$2";
            shift 2;;
        # tarball to unpack
        -t|--tarball)
            TARBALL="$2";
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

if [ "x$PREFIX_PATH" = "x" ]; then
    warn "ERROR: Please pass a path to the build output directory (--prefix)"
    exit 1
fi

#if [ "x$SOURCE_DIR" = "x" ]; then
#    warn "ERROR: Please pass a path to the unpacked source dir. (--source)"
#    exit 1
#fi

if [ "x$TARBALL" = "x" ]; then
    warn "ERROR: Please pass the filename of the tarball file (--tarball)"
    exit 1
fi

### SCRIPT MAIN LOOP ###
show_script_header
info "Unpacking and configuring $TARBALL"
#LIB_NAME=$(echo $TARBALL | sed 's/\(.*\)-[0-9].*/\1/')
# what kind of tarball is it?
if [ $(echo $TARBALL | grep -c 'gz$') -gt 0 ]; then
    UNARCHIVE_CMD="tar -zxvf"
    SOURCE_DIR=$(/usr/bin/basename $TARBALL | sed 's/\.tar\.gz$//')
elif [ $(echo $TARBALL | grep -c 'xz$') -gt 0 ]; then
    UNARCHIVE_CMD="tar -Jxvf"
    SOURCE_DIR=$(/usr/bin/basename $TARBALL | sed 's/\.tar\.xz$//')
elif [ $(echo $TARBALL | grep -c 'bz2$') -gt 0 ]; then
    UNARCHIVE_CMD="tar -jxvf"
    SOURCE_DIR=$(/usr/bin/basename $TARBALL | sed 's/\.tar\.bz2$//')
fi
info "SOURCE_DIR is ${SOURCE_DIR}"

# remove the existing source directory
if [ -d $SOURCE_DIR ]; then
    info "Found existing SOURCE_DIR: ${SOURCE_DIR}; deleting..."
    rm -rvf $SOURCE_DIR
fi

# unarchive the tarball
info "Unpack command: ${UNARCHIVE_CMD} ${TARBALL}"
# 'eval' the unarchive command so tildes expand themselves and whatnot
eval $UNARCHIVE_CMD $TARBALL

# then run configure
START_DIR=$PWD
info "Changing into ${SOURCE_DIR}"
cd $SOURCE_DIR
CONFIGURE_CMD="./configure --prefix=\"${PREFIX_PATH}\" ${CONFIG_ARGS}"
info "Running: ${CONFIGURE_CMD}"
eval $CONFIGURE_CMD 2>&1
check_exit_status $? "$CONFIGURE_CMD" " "
EXIT_STATUS=$?
info "Changing back to start directory ${START_DIR}"
cd $START_DIR

if [ $EXIT_STATUS -gt 0 ]; then
    warn "ERROR: command '${CONFIGURE_CMD}'"
    warn "ERROR: exited with an error"
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
