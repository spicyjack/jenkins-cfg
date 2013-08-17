#!/bin/sh

# Back up all of the 'config.xml' files in the Jenkins tree

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

# verbose script output by default
DRY_RUN=0

# default exit status
EXIT_STATUS=0

### SCRIPT SETUP ###
# source jenkins functions
. ~/src/jenkins/config.git/scripts/common_jenkins_functions.sh

#check_env_variable "$PRIVATE_STAMP_DIR" "PRIVATE_STAMP_DIR"
#check_env_variable "$PUBLIC_STAMP_DIR" "PUBLIC_STAMP_DIR"

GETOPT_SHORT="hqnj:s:"
GETOPT_LONG="help,quiet,dry-run,jobs:,source:"
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
    -j|--jobs       Path to the Jenkins 'jobs' directory
    -s|--source     Source path for copying 'config.xml' config files

    Example usage:
    ${SCRIPTNAME} --jobs /path/to/jenkins/jobs \\
      --source ~/src/some_git_repo.git/jobs
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
        -j|--jobs)
            JENKINS_JOBS_PATH="$2";
            shift 2;;
        # Source path
        -s|--source)
            SOURCE_PATH="$2";
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

if [ "x$JENKINS_JOBS_PATH" = "x" ]; then
    warn "ERROR: Please pass a path to the Jenkins directory (--jenkins)"
    exit 1
fi

if [ ! -d "$JENKINS_JOBS_PATH" ]; then
    warn "ERROR: Jenkins jobs path ${JENKINS_JOBS_PATH} does not exist"
    exit 1
fi

if [ "x$SOURCE_PATH" = "x" ]; then
    warn "ERROR: Please pass a source path for copying files (--target)"
    exit 1
fi

if [ ! -d "$SOURCE_PATH" ]; then
    warn "ERROR: Source path ${SOURCE_PATH} does not exist"
    exit 1
fi

### SCRIPT MAIN LOOP ###
show_script_header
info "Restoring project 'config.xml' files"
# -h == symbolic link test
#if [ -h $JENKINS_JOBS_PATH ]; then
#    if [ $(echo $JENKINS_JOBS_PATH | grep -c '/$') -eq 0 ]; then
#        JENKINS_JOBS_PATH="${JENKINS_JOBS_PATH}/"
#    fi
#fi
CONFIGS_RESTORED=0
BACKUP_JENKINS_STATEFILE=/tmp/backup_jenkins.$$

for CFG_FILE in $SOURCE_PATH/*.xml;
do
    #say "Found config: ${JENKINS_CFG}"
    # "awk NF" == number of fields, so print the last field out of all the
    # fields
    CONFIG_NAME=$(echo $CFG_FILE \
        | awk -F'/' '{last = NF; print $last}' \
        | sed 's/\.xml$//')
    if [ -d $JENKINS_JOBS_PATH/$CONFIG_NAME ]; then
        diff --brief "$JENKINS_JOBS_PATH/$CONFIG_NAME/config.xml" \
            "${CFG_FILE}" 1>/dev/null 2>&1
        DIFF_STATUS=$?
        if [ $DIFF_STATUS -gt 0 ]; then
            CONFIGS_RESTORED=$((${CONFIGS_RESTORED} + 1))
            echo $CONFIGS_RESTORED > $BACKUP_JENKINS_STATEFILE
            if [ $DRY_RUN -eq 0 ]; then
                say "Copying $CFG_FILE"
                say "to $JENKINS_JOBS_PATH/$CONFIG_NAME/config.xml"
                /bin/cp $CFG_FILE $JENKINS_JOBS_PATH/$CONFIG_NAME/config.xml
            else
                info "Diff returned non-zero; would have copied $CFG_FILE to:"
                info "$JENKINS_JOBS_PATH/$CONFIG_NAME/config.xml"
            fi
        fi
    else
        warn "Job $CONFIG_NAME not found in $JENKINS_JOBS_PATH!"
    fi
done

if [ $DRY_RUN -eq 0 ]; then
    info "Restored ${CONFIGS_RESTORED} configuration file(s)"
else
    info "Would have copied ${CONFIGS_RESTORED} configuration file(s)"
fi
if [ $EXIT_STATUS -gt 0 ]; then
    warn "ERROR: ${SCRIPTNAME} completed with errors"
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
