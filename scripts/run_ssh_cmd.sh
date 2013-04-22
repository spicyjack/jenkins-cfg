#!/bin/sh

# Run a command on a remote host via SSH

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

# default SSH port
TARGET_SSH_PORT=22

### SCRIPT SETUP ###
# source jenkins functions
. ~/src/jenkins-cfg.git/scripts/common_jenkins_functions.sh

#check_env_variable "$PRIVATE_STAMP_DIR" "PRIVATE_STAMP_DIR"
#check_env_variable "$PUBLIC_STAMP_DIR" "PUBLIC_STAMP_DIR"

GETOPT_SHORT="hqc:t:p:k:"
GETOPT_LONG="help,quiet,command:,host:,target:,port:,key:,sshkey:"
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
    -t|--target     Target host to run SSH commands on
    -p|--port       Port on the target host to connect to (default: 22/TCP)
    -c|--command    Command to run on the target host
    -k|--key        SSH key to use for the connection
    --host          Alias for --target

    NOTE: SSH passwords are currently not supported.  Just use a key, it's
    much safer/easier.

    Example usage:
    ${SCRIPTNAME} --target host1.example.com --key /path/to/ssh/key \
      --command "/bin/date"

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
        # target SSH host
        -t|--target|--host)
            TARGET_SSH_HOST="$2";
            shift 2;;
        # target SSH port
        -p|--port)
            TARGET_SSH_PORT="$2";
            shift 2;;
        # command to be run on target host
        -c|--command)
            TARGET_CMD="$2";
            shift 2;;
        # SSH key to use for the connection
        -k|--key)
            TARGET_SSH_KEY="$2";
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

if [ "x$TARGET_SSH_HOST" = "x" ]; then
    warn "ERROR: Missing hostname of target host to connect to (--target)"
    exit 1
fi

if [ "x$TARGET_SSH_CMD" = "x" ]; then
    warn "ERROR: Missing command to run on target host (--command)"
    exit 1
fi

if [ -r $TARGET_SSH_KEY ]; then
    warn "ERROR: Can't read SSH key '${TARGET_SSH_KEY}' (--key)"
    exit 1
fi

SSH_HOST_PORT="${TARGET_SSH_HOST}:${TARGET_SSH_PORT}"

### SCRIPT MAIN LOOP ###
show_script_header
info "Running '${TARGET_SSH_CMD}'"
info "on ${SSH_HOST_PORT}"
/usr/bin/ssh -i "${TARGET_SSH_KEY}" "${SSH_HOST_PORT}" "${TARGET_SSH_CMD}"
EXIT_STATUS=$?
check_exit_status $EXIT_STATUS "rm -rf" " "

if [ $EXIT_STATUS -gt 0 ]; then
    warn "ERROR: Something happened trying to run SSH command ${TARGET_SSH_CMD}"
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
