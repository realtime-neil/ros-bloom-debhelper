#!/bin/sh

# @(Package) postrm script

set -eu

readonly this="$(readlink -f "$0")"
readonly whatami="@(Package).$(basename "${this}")"

log() { echo "${whatami}: $*" >&2; }
error() { log "ERROR: $*"; }
warning() { log "WARNING: $*"; }
info() { log "INFO: $*"; }
die() {
    error "$*"
    exit 1
}

################################################################################

#DEBHELPER#

################################################################################

##############
# UDEV BEGIN #
##############
case "$1" in
    purge|remove|upgrade|failed-upgrade|abort-install|abort-upgrade|disappear)
        # TODO: Make this less aggressive; i.e., do this only when we're sure
        # the udev rules actually changed.
        if ischroot; then
            warning "chroot detected, skipping udev bounce"
        else
            if ! udevadm control --reload-rules; then
                die "FAILURE: udevadm control --reload-rules"
            fi
            if ! udevadm trigger; then
                die "FAILURE: udevadm trigger"
            fi
        fi
        ;;
    *)
        die "bad args: $*"
        ;;
esac
############
# UDEV END #
############

################################################################################

exit 0
