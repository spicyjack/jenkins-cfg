#!/bin/bash

# Download and unpack a Debian package to be used to meet library dependencies
# when cross-compiling
#
# See notes in the Jenkins project journal for various `apt-file` commands
# that could be used to get the URL to the correct file

# Copyright (c)2013 by Brian Manning (brian at xaoc dot org)
# License terms are listed at the bottom of this file
#
# Impotant URLs:
# Clone:    https://github.com/spicyjack/jenkins-config.git
# Issues:   https://github.com/spicyjack/jenkins-config/issues

### FUNCTIONS ###
# now located in common_jenkins_functions.sh
. ~/src/jenkins/config.git/scripts/common_jenkins_functions.sh

### MAIN SCRIPT ###
# what's my name?
SCRIPTNAME=$(basename $0)
# path to the perl binary

# verbose script output by default
QUIET=0

# directory with *.deb files
OUT_DIR="${HOME}/debs"

### SCRIPT SETUP ###
GETOPT_SHORT="hqo:p:l:s:t:"
GETOPT_LONG="help,quiet,outdir:,package:,log:,source:,target:"
# sets GETOPT_TEMP
# # pass in $@ unquoted so it expands, and run_getopt() will then quote it
# "$@"
# # when it goes to re-parse script arguments
run_getopt "$GETOPT_SHORT" "$GETOPT_LONG" $@

show_help () {
cat <<-EOF

    ${SCRIPTNAME} [options]

    SCRIPT OPTIONS
    -h|--help       Displays this help message
    -q|--quiet      No script output (unless an error occurs)
    -o|--outdir     Output directory to download the --package into
    -p|--package    Name of the package to download
    -l|--log        Logfile for wget to write to; default is STDERR
    -s|--source     Source architecture, aka host architecture
    -t|--target     Target architecture, what arch to download
    NOTE: Long switches (a GNU extension) do not work on BSD systems (OS X)

    Example usage:
    sh deb_download_unpack.sh --outdir ~/pkgs --package perl

EOF
}

download_tarball () {
    if [ "x$WGET_LOG" != "x" ]; then
        OUTPUT=$(wget -o $WGET_LOG -O $OUT_DIR/$DEB_PKG \
            $PKG_URL 2>&1)
        SCRIPT_EXIT=$?
    else
        wget -O $OUT_DIR/$DEB_PKG $PKG_URL 2>&1
        SCRIPT_EXIT=$?
    fi
    # check the status of the last command
    check_exit_status $SCRIPT_EXIT "wget for ${PKG_URL}" "$OUTPUT"
    if [ $SCRIPT_EXIT -eq 0 ]; then
        info "Download of ${DEB_PKG} successful!"
    else
        info "Download of ${DEB_PKG} failed!"
        # clean up after ourselves
        if [ -e $OUT_DIR/$DEB_PKG ]; then
            /bin/rm -f $OUT_DIR/$DEB_PKG
        fi
    fi
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
        # debian package to download
        -p|--package)
            DEB_PKG=$2;
            shift 2;;
        # output directory
        -o|--outdir)
            OUT_DIR=$2;
            shift 2;;
        # output to log?
        -l|--log)
            WGET_LOG=$2;
            shift 2;;
        # source architecture, what arch are we running on?
        -s|--source)
            SOURCE_ARCH=$2;
            shift 2;;
        # target architecture, what arch we want to download and unpack
        -t|--target)
            TARGET_ARCH=$2;
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

    ### SCRIPT MAIN LOOP ###
    show_script_header
    info "Source architecture: ${SOURCE_ARCH}"
    info "Target architecture: ${TARGET_ARCH}"
    info "Debian package to download: ${DEB_PKG}"
    info "to directory: ${OUT_DIR}"

    # check to see if OUT_DIR exists; if not create it
    if [ ! -d $OUT_DIR ]; then
        OUTPUT=$(mkdir -p $OUT_DIR)
        check_exit_status $? "mkdir $OUT_DIR" "$OUTPUT"
    fi

    # query the package system to get a URL to the file for the native
    # architecture
    APT_GET_OUT=$(/usr/bin/apt-get --dry-run --print-uris download ${DEB_PKG})
    PKG_URL=$(echo ${APT_GET_OUT} | awk '{print $1}')
    PKG_URL=$(echo ${PKG_URL} | sed "s/_${SOURCE_ARCH}/_${TARGET_ARCH}/")
    PKG_FILENAME=$(echo ${APT_GET_OUT} | awk '{print $2}')
    PKG_FILENAM=$(echo ${PKG_FILENAME} \
        | sed "s/_${SOURCE_ARCH}/_${TARGET_ARCH}/")
    PKG_SIZE=$(echo ${APT_GET_OUT} | awk '{print $3}')
    PKG_CHECKSUM=$(echo ${APT_GET_OUT} | awk '{print $4}')
    echo "Package URL: ${PKG_URL}"
    echo "Package filename: ${PKG_FILENAME}"
    echo "Package size: ${PKG_SIZE}"
    echo "Package checksum: ${PKG_CHECKSUM}"
    exit 0
    # check to see if the tarball is in OUT_DIR before downloading
    # FIXME check for zero-length files, warn if one is found
    if [ ! -e $OUT_DIR/$PKG_FILENAME]; then
        # log wget output, or send to STDERR?
        download_tarball
    else
        FILE_SIZE=$(/usr/bin/stat --printf="%s" ${OUT_DIR}/${PKG_FILENAME})
        info "File already exists: ${OUT_DIR}/${PKG_FILENAME};"
        if [ $FILE_SIZE -eq 0 ]; then
            info "File is zero byes; removing and redownloading"
            rm -f ${OUT_DIR}/${DEB_PKG}
            download_tarball
        else
            info "File size: ${FILE_SIZE} byte(s)"
            info "Skipping download..."
        fi
    fi

    info "Unpacking and configuring ${DEB_PKG} in $WORKSPACE/artifacts"
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

    # unpack the debian package in the artifacts directory
    /usr/bin/dpkg --unpack ${OUT_DIR}/${DEB_PKG}
    EXIT_STATUS=$?
    if [ $EXIT_STATUS -gt 0 ]; then
        warn "ERROR: Unpacking ${DEB_PKG} resulted in an error"
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

# vim: set filetype=sh shiftwidth=4 tabstop=4
# end of line
