#!/bin/sh

# Back up all of the 'config.xml' files in the Jenkins tree

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

# verbose script output by default
DRY_RUN=0

# default exit status
EXIT_STATUS=0

### SCRIPT SETUP ###
# source jenkins functions
. ~/src/jenkins-cfg.git/scripts/common_jenkins_functions.sh

#check_env_variable "$PRIVATE_STAMP_DIR" "PRIVATE_STAMP_DIR"
#check_env_variable "$PUBLIC_STAMP_DIR" "PUBLIC_STAMP_DIR"

GETOPT_SHORT="hqnj:t:"
GETOPT_LONG="help,quiet,dry-run,jenkins:,target:"
# sets GETOPT_TEMP
# pass in $@ unquoted so it expands, and run_getopt() will then quote it "$@"
# when it goes to re-parse script arguments
run_getopt "$GETOPT_SHORT" "$GETOPT_LONG" $@

show_help () {
cat <<-EOF

    ${SCRIPTNAME} [options]

    SCRIPT OPTIONS
    -h|--help       Displays this help message
    -q|--quiet      No script output (unless an error occurs)
    -n|--dry-run    Explain what would be done, don't actually do it
    -j|--jenkins    Path to the Jenkins 'jobs' directory
    -t|--target     Target path for copying 'config.xml' config files

    Example usage:
    ${SCRIPTNAME} --jenkins /path/to/jenkins/jobs \\
      --target ~/src/jenkins-cfg.git/jobs/Platform
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
        # don't actually do anything
        -n|--dry-run)
            DRY_RUN=1
            shift;;
        # Path to Jenkins install
        -j|--jenkins)
            JENKINS_PATH="$2";
            shift 2;;
        # Target path
        -t|--target)
            TARGET_PATH="$2";
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

if [ "x$JENKINS_PATH" = "x" ]; then
    warn "ERROR: Please pass a path to the Jenkins directory (--jenkins)"
    exit 1
fi

if [ ! -d "$JENKINS_PATH" ]; then
    warn "ERROR: jenkins-cfg.git path ${JENKINS_PATH} does not exist"
    exit 1
fi

if [ "x$TARGET_PATH" = "x" ]; then
    warn "ERROR: Please pass a target path for copying files (--target)"
    exit 1
fi

if [ ! -d "$TARGET_PATH" ]; then
    warn "ERROR: Target path ${TARGET_PATH} does not exist"
    exit 1
fi

### SCRIPT MAIN LOOP ###
show_script_header
info "Backing up 'config.xml' files"
info "Running 'find' in Jenkins path: ${JENKINS_PATH}"
# -h == symbolic link test
if [ -h $JENKINS_PATH ]; then
    if [ $(echo $JENKINS_PATH | grep -c '/$') -eq 0 ]; then
        JENKINS_PATH="${JENKINS_PATH}/"
    fi
fi
find "$JENKINS_PATH" -name "config.xml" -print0 2>/dev/null | sort -z \
    | while IFS= read -d $'\0' JENKINS_CFG;
do
    say "Found config: ${JENKINS_CFG}"
    JOB_NAME=$(dirname "${JENKINS_CFG}" \
        | awk -F"/" '{last = NF; print $last;}');
    TARGET_PATH=$(echo $TARGET_PATH | sed 's!/$!!');
    TARGET_FILE="$TARGET_PATH/${JOB_NAME}.xml"
    diff --brief "${JENKINS_CFG}" "${TARGET_FILE}" 1>/dev/null 2>&1
    DIFF_STATUS=$?
    if [ $DIFF_STATUS -gt 0 ]; then
        if [ $DRY_RUN -eq 0 ]; then
            /bin/cp --force --verbose "$JENKINS_CFG" "$TARGET_FILE"
        else
            echo "  Need to copy files with changes, but dry-run was set;"
            echo "  Source: $JENKINS_CFG"
            echo "  Target: $TARGET_FILE"
        fi
        EXIT_STATUS=$?
    fi
done

if [ $EXIT_STATUS -gt 0 ]; then
    warn "ERROR: backup_jenkins.sh completed with errors"
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
