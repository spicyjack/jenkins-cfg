#!/bin/bash

# Download a file if it doesn't exist on the local filesystem

# Copyright (c)2012-2013 by Brian Manning (brian at xaoc dot org)
# License terms are listed at the bottom of this file
#
# Impotant URLs:
# Clone:    https://github.com/spicyjack/jenkins-config.git
# Issues:   https://github.com/spicyjack/jenkins-config/issues

### FUNCTIONS ###
# now located in common_jenkins_functions.sh
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

### MAIN SCRIPT ###
# what's my name?
SCRIPTNAME=$(basename $0)

# verbose script output by default
QUIET=0

### SCRIPT SETUP ###
GETOPT_SHORT="c:f:hl:o:qu:"
GETOPT_LONG="compare:,file:,help,log:,outdir:,quiet,url:"
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
    -o|--outdir     Output directory to download the --file into
    -f|--file       Name of tarball file to download
    -c|--compare    Compare checksums, overwrite this file if different
    -l|--log        Logfile for wget to write to; default is STDERR
    -u|--url        Base URL where --file can be found and downloaded from

    NOTES:
    - Long switches (a GNU extension) do not work on BSD systems (OS X)
    - The '--compare' switch will cause the downloaded file to overwrite the
      file given by the '--compare' switch if the checksums differ

    Example usage:
    sh download.sh -o ~/tmp -f perl-5.16.2.tar.gz \\
      -u http://www.cpan.org/src/5.0
    sh download.sh --outdir ~/tmp --file perl-5.16.2.tar.gz \\
      --url http://www.cpan.org/src/5.0
EOF
}

download_tarball () {
    if [ "x$WGET_LOG" != "x" ]; then
        OUTPUT=$(wget -o $WGET_LOG -O $OUTDIR/$TARBALL \
            $BASE_URL/$TARBALL 2>&1)
        SCRIPT_EXIT=$?
    else
        wget -O $OUTDIR/$TARBALL $BASE_URL/$TARBALL 2>&1
        SCRIPT_EXIT=$?
    fi
    # check the status of the last command
    check_exit_status $SCRIPT_EXIT "wget for ${BASE_URL}/${TARBALL}" "$OUTPUT"
    if [ $SCRIPT_EXIT -eq 0 ]; then
        info "Download of ${TARBALL} successful!"
    else
        info "Download of ${TARBALL} failed!"
        if [ -e $OUTDIR/$TARBALL ]; then
            /bin/rm -f $OUTDIR/$TARBALL
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
        # compare (checksum) the downloaded file with this file
        -c|--compare)
            COMPARE_FILE=$2;
            shift 2;;
        # tarball file that needs to be downloaded
        -f|--file)
            TARBALL=$2;
            shift 2;;
        # output directory
        -o|--outdir)
            OUTDIR=$2;
            shift 2;;
        # output to log?
        -l|--log)
            WGET_LOG=$2;
            shift 2;;
        # Base URL that contains $FILE
        -u|--url)
            BASE_URL=$2;
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
info "Download file ${BASE_URL}/${TARBALL}"
info "to directory ${OUTDIR}"

# check to see if OUTDIR exists; if not create it
if [ ! -d $OUTDIR ]; then
    OUTPUT=$(mkdir -p $OUTDIR)
    check_exit_status $? "mkdir $OUTDIR" "$OUTPUT"
fi

# check to see if the tarball is in OUTDIR before downloading
# FIXME check for zero-length files, warn if one is found

if [ ! -e $OUTDIR/$TARBALL ]; then
    # log wget output, or send to STDERR?
    download_tarball
else
    FILE_SIZE=$(/usr/bin/stat --printf="%s" ${OUTDIR}/${TARBALL})
    info "File already exists: ${OUTDIR}/${TARBALL};"
    if [ $FILE_SIZE -eq 0 ]; then
        info "File is zero byes; removing and redownloading"
        rm -f ${OUTDIR}/${TARBALL}
        download_tarball
    else
        info "File size: ${FILE_SIZE} byte(s)"
        info "Skipping download..."
    fi
fi

exit ${SCRIPT_EXIT}

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
