#!/bin/sh
# other possible choices here are /bin/bash or maybe /bin/ksh

# Download a file if it doesn't exist on the local filesystem

# Copyright (c)2012-2013 by Brian Manning (brian at xaoc dot org)
# License terms are listed at the bottom of this file
#
# Impotant URLs:
# Clone:    https://github.com/spicyjack/jenkins-cfg.git
# Issues:   https://github.com/spicyjack/jenkins-cfg/issues

### FUNCTIONS ###
# now located in common_jenkins_functions.sh
. ~/src/jenkins-cfg.git/scripts/common_jenkins_functions.sh

### MAIN SCRIPT ###
# what's my name?
SCRIPTNAME=$(basename $0)
# path to the perl binary

# verbose script output by default
QUIET=0

### SCRIPT SETUP ###
# BSD's getopt is simpler than the GNU getopt; we need to detect it
OSDETECT=$(/usr/bin/env uname -s)
if [ $OSDETECT = "Darwin" ]; then
    # this is the BSD part
    TEMP=$(/usr/bin/getopt f:hl:o:qu: $* 2>/dev/null)
elif [ $OSDETECT = "Linux" ]; then
    # and this is the GNU part
    TEMP=$(/usr/bin/getopt -o f:hl:o:qu: \
        --long file:,help,log:,outdir:,quiet,url: \
        -n '${SCRIPTNAME}' -- "$@")
else
    echo "Error: Unknown OS Type.  I don't know how to call"
    echo "'getopts' correctly for this operating system.  Exiting..."
    exit 1
fi

# this script requires options; if no options were passed to it, exit with an
# error
if [ $# -eq 0 ] ; then
    echo "ERROR: this script has required options that are missing" >&2
    echo "Run '${SCRIPTNAME} --help' to see script options" >&2
    exit 1
fi

show_help () {
cat <<-EOF

    ${SCRIPTNAME} [options]

    SCRIPT OPTIONS
    -h|--help       Displays this help message
    -q|--quiet      No script output (unless an error occurs)
    -o|--outdir     Output directory to download the --file into
    -f|--file       Name of tarball file to download
    -l|--log        Logfile for wget to write to; default is STDERR
    -u|--url        Base URL where --file can be found and downloaded from
    NOTE: Long switches (a GNU extension) do not work on BSD systems (OS X)

    Example usage:
    sh download.sh -o ~/tmp -f perl-5.16.2.tar.gz \
      -u http://www.cpan.org/src/5.0
    sh download.sh --outdir ~/tmp --file perl-5.16.2.tar.gz \
      --url http://www.cpan.org/src/5.0
EOF
}

# Note the quotes around `$TEMP': they are essential!
# read in the $TEMP variable
eval set -- "$TEMP"

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
            LOGFILE=$2;
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
            echo "ERROR: unknown option '$1'" >&2
            echo "ERROR: use --help to see all script options" >&2
            exit 1
            ;;
    esac
done

### SCRIPT MAIN LOOP ###
if [ $QUIET -ne 1 ]; then
    echo "-> Downloading file ${BASE_URL}/${TARBALL}"
    echo "-> to directory ${OUTDIR}"
fi

# check to see if OUTDIR exists; if not create it
if [ ! -d $OUTDIR ]; then
    OUTPUT=$(mkdir -p $OUTDIR)
    check_exit_status $? "mkdir $OUTDIR" "$OUTPUT"
fi

# check to see if the tarball is in OUTDIR before downloading
if [ ! -e $OUTDIR/$TARBALL ]; then
    # log wget output, or send to STDERR?
    if [ "x$LOG" != "x" ]; then
        WGET_OPTS="-o $LOG"
    fi
    eval OUTPUT=$(wget $WGET_OPTS -O $OUTDIR/$TARBALL \
        $BASE_URL/$TARBALL 2>/dev/null)
    check_exit_status $? "wget for ${BASE_URL}/${TARBALL}" "$OUTPUT"
    echo "-> Download complete!"
else
    echo "-> File already exists: ${OUTDIR}/${TARBALL}"
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
