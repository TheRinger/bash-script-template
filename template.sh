#!/usr/bin/env bash

# A best practices Bash script template with many useful functions. This file
# combines the source.sh & script.sh files into a single script. If you want
# your script to be entirely self-contained then this should be what you want!

# A better class of script...
set -o errexit          # Exit on most errors (see the manual)
set -o errtrace         # Make sure any error trap is inherited
set -o nounset          # Disallow expansion of unset variables
set -o pipefail         # Use last non-zero exit code in a pipeline
#set -o xtrace          # Trace the execution of the script (debug)

# DESC: Handler for unexpected errors
# ARGS: $1 (optional): Exit code (defaults to 1)
function script_trap_err() {
    # Disable the error trap handler to prevent potential recursion
    trap - ERR

    # Consider any further errors non-fatal to ensure we run to completion
    set +o errexit
    set +o pipefail

    # Exit with failure status
    if [[ $# -eq 1 && $1 =~ ^[0-9]+$ ]]; then
        exit "$1"
    else
        exit 1
    fi
}


# DESC: Handler for exiting the script
# ARGS: None
function script_trap_exit() {
    cd "$orig_cwd"

    # Restore terminal colours
    tput sgr0
}


# DESC: Exit script with the given message
# ARGS: $1 (required): Message to print on exit
#       $2 (optional): Exit code (defaults to 0)
function script_exit() {
    if [[ $# -eq 1 ]]; then
        echo "$1"
        exit 0
    fi

    if [[ $# -eq 2 && $2 =~ ^[0-9]+$ ]]; then
        echo -e "$1"
        # If we've been provided a non-zero exit code run the error trap
        if [[ $2 -ne 0 ]]; then
            script_trap_err "$2"
        else
            exit 0
        fi
    fi

    script_exit "Invalid arguments passed to script_exit()!" 2
}


# DESC: Generic script initialisation
# ARGS: None
function script_init() {
    # Useful paths
    readonly orig_cwd="$PWD"
    readonly script_path="${BASH_SOURCE[0]}"
    readonly script_dir="$(dirname "$script_path")"
    readonly script_name="$(basename "$script_path")"

    # Text attributes
    readonly ta_none="\e[0m"
    readonly ta_bold="\e[1m"
    readonly ta_uscore="\e[4m"
    readonly ta_blink="\e[5m"
    readonly ta_reverse="\e[7m"
    readonly ta_conceal="\e[8m"

    # Foreground codes
    readonly fg_black="\e[30m"
    readonly fg_blue="\e[34m"
    readonly fg_cyan="\e[36m"
    readonly fg_green="\e[32m"
    readonly fg_magenta="\e[35m"
    readonly fg_red="\e[31m"
    readonly fg_white="\e[37m"
    readonly fg_yellow="\e[33m"

    # Background codes
    readonly bg_black="\e[40m"
    readonly bg_blue="\e[44m"
    readonly bg_cyan="\e[46m"
    readonly bg_green="\e[42m"
    readonly bg_magenta="\e[45m"
    readonly bg_red="\e[41m"
    readonly bg_white="\e[47m"
    readonly bg_yellow="\e[43m"
}


# DESC: Pretty print the provided string
# ARGS: $1 (required): Message to print (defaults to a green foreground)
#       $2 (optional): Colour to print the message with. This can be an ANSI
#                      escape code or one of the prepopulated colour variables.
function pretty_print() {
    if [[ $# -eq 0 || $# -gt 2 ]]; then
        script_exit "Invalid arguments passed to pretty_print()!" 2
    fi

    if [[ -z ${no_colour-} ]]; then
        if [[ $# -eq 2 ]]; then
            echo -n -e "$2"
        else
            echo -n -e "$fg_green"
        fi
    fi

    echo "$1"

    if [[ -z ${no_colour-} ]]; then
        # Restore terminal colours
        tput sgr0
    fi
}


# DESC: Only pretty_print() the provided string if verbose mode is enabled
# ARGS: $@ (required): Passed through to pretty_pretty() function
function verbose_print() {
    if [[ -n ${verbose-} ]]; then
        pretty_print "$@"
    fi
}


# DESC: Check a binary exists in the search path
# ARGS: $1 (required): Name of the binary to test for existence
#       $2 (optional): Set non-zero to treat failure as a fatal error
function check_binary() {
    if [[ $# -ne 1 && $# -ne 2 ]]; then
        script_exit "Invalid arguments passed to check_binary()!" 2
    fi

    if ! command -v "$1" > /dev/null 2>&1; then
        if [[ ${2-} =~ ^0$ ]]; then
            script_exit "Missing dependency: Couldn't locate $1." 1
        else
            verbose_print "Missing dependency: $1" "$fg_red"
            return 1
        fi
    fi

    verbose_print "Found dependency: $1"
    return 0
}


# DESC: Validate we have superuser access as root (via sudo if requested)
# ARGS: $1 (optional): Set to any value to not attempt root access via sudo
# shellcheck disable=SC2120
function check_superuser() {
    if [[ $# -gt 1 ]]; then
        script_exit "Invalid arguments passed to check_superuser()!" 2
    fi

    local superuser test_euid
    if [[ $EUID -eq 0 ]]; then
        superuser="true"
    elif [[ -z ${1-} ]]; then
        if check_binary sudo; then
            pretty_print "Sudo: Updating cached credentials for future use..."
            if ! sudo -v; then
                verbose_print "Sudo: Couldn't acquire credentials..." "$fg_red"
            else
                # shellcheck disable=SC2016
                test_euid="$(sudo -H -- "$BASH" -c 'echo $EUID')"
                if [[ $test_euid -eq 0 ]]; then
                    superuser="true"
                fi
            fi
        fi
    fi

    if [[ -z $superuser ]]; then
        verbose_print "Unable to acquire superuser credentials." "$fg_red"
        return 1
    fi

    verbose_print "Successfully acquired superuser credentials."
    return 0
}


# DESC: Run the requested command as root (via sudo if requested)
# ARGS: $1 (optional): Set to zero to not attempt execution via sudo
#       $@ (required): Passed through for execution as root user
function run_as_root() {
    local try_sudo
    if [[ ${1-} =~ ^0$ ]]; then
        try_sudo="true"
        shift
    fi

    if [[ $# -eq 0 ]]; then
        script_exit "Invalid arguments passed to run_as_root()!" 2
    fi

    if [[ $EUID -eq 0 ]]; then
        "$@"
    elif [[ -z ${try_sudo-} ]]; then
        sudo -H -- "$@"
    else
        script_exit "Unable to run requested command as root: $*" 1
    fi
}


# DESC: Usage help
# ARGS: None
function script_usage() {
    echo 'Usage:
     -h|--help                  Displays this help
     -v|--verbose               Displays verbose output
    -nc|--no-colour             Disables colour output'
}


# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
function parse_params() {
    local param
    while [[ $# -gt 0 ]]; do
        param="$1"
        shift
        case $param in
            -h|--help)
                script_usage
                exit 0
                ;;
            -v|--verbose)
                verbose="true"
                ;;
            -nc|--no-colour)
                no_colour="true"
                ;;
            *)
                script_exit "Invalid parameter was provided: $param" 2
                ;;
            esac
    done
}


# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
function main() {
    trap "script_trap_err" ERR
    trap "script_trap_exit" EXIT

    script_init
    parse_params "$@"
}


# Make it rain
main "$@"

# vim: syntax=sh cc=80 tw=79 ts=4 sw=4 sts=4 et sr
