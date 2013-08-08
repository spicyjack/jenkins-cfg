#!/bin/sh

# Unpack a source tarball and run ./configure on it

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

# don't run ./configure; 0 = run configure, 1 = don't run configure
NO_CONFIGURE=0

### SCRIPT SETUP ###
# source jenkins functions
. ~/src/jenkins/config.git/scripts/common_jenkins_functions.sh

#check_env_variable "$PRIVATE_STAMP_DIR" "PRIVATE_STAMP_DIR"
#check_env_variable "$PUBLIC_STAMP_DIR" "PUBLIC_STAMP_DIR"

GETOPT_SHORT="hqp:nc:a:t:"
GETOPT_LONG="help,quiet,prefix:,no-config,cross-compile:,cross:"
GETOPT_LONG="${GETOPT_LONG},tarball:"
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
    -n|--no-config      Don't run './configure'; use for CMake and friends
    -c|--cross-compile  Cross compile to 'host' platform
    -t|--tarball        Filename of tarball to download and/or unpack

    Example usage:
    # for GNU Make's ./configure
    ${SCRIPTNAME} --prefix=\${WORKSPACE}/output \\
      --tarball=\$TARBALL_DIR/tarball_name-version.tar.gz \\
      -- --arg1=foo --arg2=bar

    ${SCRIPTNAME} --prefix=\${WORKSPACE}/output \\
      --tarball=\$TARBALL_DIR/tarball_name-version.tar.gz \\
      --cross-compile=arm-unknown-linux-gnueabi \\
      -- --arg1=foo --arg2=bar

    # for CMake
    ${SCRIPTNAME} --no-config \\
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
        # configure args
        -a|--args|--config-args|--config|--configargs|--configure-args)
            CONFIG_ARGS="$2";
            shift 2;;
        # cross-compilation
        -c|--cross|--cross-compile)
            CROSS_COMPILE="$2";
            shift 2;;
        # Don't run ./configure
        -n|--no-config)
            NO_CONFIGURE=1
            shift;;
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

if [ "x$PREFIX_PATH" = "x" -a $NO_CONFIGURE -eq 0 ]; then
    warn "ERROR: Please pass a path to the build output directory (--prefix)"
    exit 1
fi

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
elif [ $(echo $TARBALL | grep -c 'zip$') -gt 0 ]; then
    UNARCHIVE_CMD="unzip"
    SOURCE_DIR=$(/usr/bin/basename $TARBALL | sed 's/\.zip$//')
elif [ $(echo $TARBALL | grep -c '7z$') -gt 0 ]; then
    UNARCHIVE_CMD="unlzma"
    SOURCE_DIR=$(/usr/bin/basename $TARBALL | sed 's/\.7z$//')
else
    echo "ERROR: Don't know how to unpack $TARBALL!"
    exit 1
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

if [ $NO_CONFIGURE -eq 0 ]; then
# then run configure
    START_DIR=$PWD
    if [ -d ${SOURCE_DIR} ]; then
        info "Changing into ${SOURCE_DIR}"
        cd $SOURCE_DIR
        CONFIGURE_CMD="./configure --prefix=\"${PREFIX_PATH}\""
        if [ $# -gt 0 ]; then
            CONFIGURE_CMD="${CONFIGURE_CMD} ${@}"
        fi
        if [ "x${CROSS_COMPILE}" != "x" ]; then
            # architecture we're building on
            CROSS_BUILD_ARCH=$(uname -m)
            CROSS_HOST_ARCH=$CROSS_COMPILE
            # NOTE: --target shouldn't be needed according to the docs for GNU
            # Autoconf
            CONFIGURE_CMD="${CONFIGURE_CMD} --build=${CROSS_BUILD_ARCH}"
            CONFIGURE_CMD="${CONFIGURE_CMD} --host=${CROSS_HOST_ARCH}"
        fi
        info "Running: ${CONFIGURE_CMD}"
        eval $CONFIGURE_CMD 2>&1
        check_exit_status $? "$CONFIGURE_CMD" " "
        EXIT_STATUS=$?
        info "Changing back to start directory ${START_DIR}"
        cd $START_DIR
    else
        warn "ERROR: Source directory ${SOURCE_DIR} does not exist!"
        EXIT_STATUS=1
    fi
else
    info "Skipping running of './configure"
fi

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
