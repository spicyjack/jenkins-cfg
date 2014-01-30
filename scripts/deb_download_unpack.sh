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

# dry-run the request?
# - 1 = yes, simulate script execution
# - 0 = no, don't simulate script execution
# - default = 0, 'no'
DRY_RUN=0

# download files only, don't unpack
# - 1 = yes, download only
# - 0 = no, download and unpack
# - default = 0, download and unpack
DOWNLOAD_ONLY=0

# directory with *.deb files
PKG_DIR="${HOME}/debs"

# getops options lists
GETOPT_SHORT="hqneo:p:o:l:s:a:t:d"
GETOPT_LONG="help,quiet,dry-run,examples,log:"
# download-only options
GETOPT_LONG="${GETOPT_LONG},download-only,download"
# for --package-dir
GETOPT_LONG="${GETOPT_LONG},package-dir:,pkg-dir:,pkgdir:,package:,pkgs:"
# for --output-dir
GETOPT_LONG="${GETOPT_LONG},output-dir:,output:,outdir:"
# for --host-arch
GETOPT_LONG="${GETOPT_LONG},host-arch:,arch:,host"
# for --target-arch
GETOPT_LONG="${GETOPT_LONG},target:,target-arch:,tgt-arch:"

show_help () {
cat <<-EOH

    ${SCRIPTNAME} [options]

    GENERAL OPTIONS
    -h|--help           Displays this help message
    -q|--quiet          No script output (unless an error occurs)
    -n|--dry-run        Do everything but actually download/unpack the file
    -e|--examples       Show usage examples

    SCRIPT OPTIONS
    -p|--package-dir    Output directory for downloaded packages
    -o|--output-dir     Output directory for unpacking packages
    -l|--log            Logfile for wget to write to; default is STDERR
    -a|--host-arch      Host architecture
    -t|--target-arch    Target architecture, what arch to download
    -d|--download-only  Just download the file, don't unpack it

    NOTE: Long switches (a GNU extension) do not work on BSD systems (OS X)

    Use '${SCRIPTNAME} --examples' to show usage examples

EOH
}

show_examples () {
cat <<-EOE

    Examples of script usage:

    # download and unpack packages
    sh deb_download_unpack.sh --package-dir ~/pkgs \\
      --output-dir \$WORKSPACE/artifacts \\
      --target-arch armhf -- perl libsdl1.2debian libsdl-net1.2

    # download and unpack packages, log to a file
    sh deb_download_unpack.sh --package-dir ~/pkgs \\
      --output-dir \$WORKSPACE/artifacts --log ~/download_unpack.log \\
      --target-arch armhf -- perl libsdl1.2debian libsdl-net1.2

    # download only, don't unpack packages
    sh deb_download_unpack.sh --package-dir ~/pkgs --download-only \\
      --target-arch armhf -- perl libsdl1.2debian libsdl-net1.2

    Use '${SCRIPTNAME} --help' to see all script options

EOE
}


# from 'common_jenknis_functions.sh'; sets GETOPT_TEMP
# pass in $@ unquoted so it expands, and run_getopt() will then quote it "$@"
# when it goes to re-parse script arguments
run_getopt "$GETOPT_SHORT" "$GETOPT_LONG" $@

download_tarball () {
    if [ $DRY_RUN -eq 1 ]; then
        # simulate a download
        info "--dry-run called on commandline; simulating download"
    else
        # do the actual download
        info "Calling 'wget -O $PKG_DIR/$PKG_FILENAME $PKG_URL'"
        if [ "x$WGET_LOG" != "x" ]; then
            OUTPUT=$(eval wget -q -o $WGET_LOG -O $PKG_DIR/$PKG_FILENAME \
                $PKG_URL 2>&1)
            SCRIPT_EXIT=$?
        else
            OUTPUT=$(eval wget -q -O $PKG_DIR/$PKG_FILENAME $PKG_URL 2>&1)
            SCRIPT_EXIT=$?
        fi
        # check the status of the last command
        check_exit_status $SCRIPT_EXIT "wget for ${PKG_URL}" "$OUTPUT"
        if [ $SCRIPT_EXIT -eq 0 ]; then
            info "Download of '${PACKAGE_NAME}' successful!"
        else
            info "Download of '${PACKAGE_NAME}' failed!"
            # clean up after ourselves
            if [ -e $PKG_DIR/$PKG_FILENAME ]; then
                /bin/rm -f $PKG_DIR/$PKG_FILENAME
            fi
        fi
    fi
}

set_package_filename_url () {
    # query the package system to get a URL to the file for the native
    # architecture
    APT_GET_OUT=$(/usr/bin/apt-get --dry-run --print-uris \
        download ${PACKAGE_NAME})
    PKG_URL=$(echo ${APT_GET_OUT} | awk '{print $1}')
    PKG_URL=$(echo ${PKG_URL} | sed "s/_${HOST_ARCH}/_${TARGET_ARCH}/")
    PKG_FILENAME=$(echo ${APT_GET_OUT} | awk '{print $2}')
    PKG_FILENAME=$(echo ${PKG_FILENAME} \
        | sed "s/_${HOST_ARCH}/_${TARGET_ARCH}/")
    #PKG_SIZE=$(echo ${APT_GET_OUT} | awk '{print $3}')
    #PKG_CHECKSUM=$(echo ${APT_GET_OUT} | awk '{print $4}')
    info "Package URL: ${PKG_URL}"
    info "Package filename: ${PKG_FILENAME}"
    # package size and checksum are for the --host package, not --target
    # package
    #echo "Package size: ${PKG_SIZE}"
    #echo "Package checksum: ${PKG_CHECKSUM}"
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
        # do everything but the actual download and unpack
        -n|--dry-run)
            DRY_RUN=1
            shift;;
        # show the script usage examples
        -e|--examples)
            show_examples
            exit 0;;
        # download only, don't unpack
        -d|--download|--download-only)
            DOWNLOAD_ONLY=1
            shift;;
        # debian package to download
        -p|--package-dir|--pkgdir|--pkg-dir|--package|--pkgs)
            PKG_DIR=$2;
            shift 2;;
        # output directory
        -o|--outdir|--output-dir|--output)
            OUTPUT_DIR=$2;
            shift 2;;
        # output to log?
        -l|--log)
            WGET_LOG=$2;
            shift 2;;
        # source architecture, what arch are we running on?
        -a|--host-arch|--arch|--host)
            HOST_ARCH=$2;
            shift 2;;
        # target architecture, what arch we want to download and unpack
        -t|--target|--target-arch|--tgt-arch)
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

    # check for package directory
    if [ ! -d $PKG_DIR ]; then
        warn "ERROR: Missing package directory '$PKG_DIR'"
        warn "ERROR: use --help to see all script options"
        exit 1
    fi

    # check for output directory
    if [ ! -d $OUTPUT_DIR ]; then
        warn "ERROR: Missing output directory '$OUTPUT_DIR'"
        warn "ERROR: use --help to see all script options"
        exit 1
    fi

    # check for target architecture
    if [ "x$TARGET_ARCH" = "x" ]; then
        warn "ERROR: Script requires '--target-arch' argument;"
        warn "ERROR: (What architecture to download a package for)"
        exit 1
    fi

    # last check, verify a list of packages was passed in
    if [ $# -eq 0 ]; then
        warn "ERROR: need list of packages to download/unpack"
        warn "ERROR: use --help to see all script options"
        exit 1
    fi

    # no more checks, we have the info we need to run
    show_script_header

    # set a host architecture if the user didn't specify one
    if [ "x$HOST_ARCH" = "x" ]; then
        info "Set host architecture via 'dpkg --print-architecture'"
        HOST_ARCH=$(dpkg --print-architecture)
    fi

    # let the user see script settings before running
    info "Script options:"
    info "Host architecture: ${HOST_ARCH}"
    info "Target architecture: ${TARGET_ARCH}"
    info "Package directory: ${PKG_DIR}"
    info "Output directory: ${OUTPUT_DIR}"

    # check to see if PKG_DIR exists; if not create it
    if [ ! -d $PKG_DIR ]; then
        OUTPUT=$(mkdir -p $PKG_DIR)
        check_exit_status $? "mkdir $PKG_DIR" "$OUTPUT"
    fi

    while [ $# -gt 0 ];
    do
        PACKAGE_NAME=$1
        echo "~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~"
        info "Now processing package: ${PACKAGE_NAME}"
        # Sets $PKG_DIR and $PKG_FILENAME
        set_package_filename_url
        # check to see if the tarball is in PKG_DIR before downloading
        if [ ! -e $PKG_DIR/$PKG_FILENAME ]; then
            # log wget output, or send to STDERR?
            download_tarball
        else
            FILE_SIZE=$(/usr/bin/stat --printf="%s" \
                ${PKG_DIR}/${PKG_FILENAME})
            info "File already exists: ${PKG_DIR}/${PKG_FILENAME}"
            if [ $FILE_SIZE -eq 0 ]; then
                info "File is zero byes; removing and redownloading"
                rm -f ${PKG_DIR}/${PKG_FILENAME}
                download_tarball
            else
                info "File size: ${FILE_SIZE} byte(s)"
                info "Skipping download..."
            fi
        fi

        if [ $DOWNLOAD_ONLY -eq 0 ]; then
            if [ $DRY_RUN -eq 1 ]; then
                # simulate unpacking
                info "--dry-run called on commandline; simulating unpacking"
            else
                # unpack the debian package in the artifacts directory
                info "Unpacking ${PACKAGE_NAME} to ${OUTPUT_DIR}"
                /usr/bin/dpkg-deb --extract ${PKG_DIR}/${PKG_FILENAME} \
                    $OUTPUT_DIR
                EXIT_STATUS=$?
                if [ $EXIT_STATUS -gt 0 ]; then
                    warn "ERROR: Unpacking ${PACKAGE_NAME} resulted in an error"
                fi
            fi
        fi

       # pop a file argument off of the arg stack
        shift
    done

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
