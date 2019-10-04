#!/bin/sh

# @(Package) postinst script

# This file is an amalgamation of the following package contents:
#
# * dh-make_2.201701_all/usr/share/debhelper/dh_make/debian/postinst.ex
# * dh-sysuser_1.3.1_all/usr/share/debhelper/autoscripts/postinst-sysuser
# * sysuser-helper_1.3.1_all/lib/sysuser-helper/sysuser-helper
#
# They were harvested on 2019.09.24 from an Ubuntu Bionic host via
#
#     $ apt-get download dh-make dh-sysuser sysuser-helper
#
# The dh-make `postinst.ex` is an example file. The other files have been
# pilfered because --- while the packages `dh-sysuser` and `sysuser-helper` are
# available for Ubuntu Bionic --- they are not available for Ubuntu Xenial.
#
# References:
#
# * https://unix.stackexchange.com/questions/47880/how-debian-package-should-create-user-accounts/147123#147123
# * https://wiki.debian.org/AccountHandlingInMaintainerScripts
# * https://www.tldp.org/LDP/www.debian.org/doc/manuals/securing-debian-howto/ch9.en.html#fr64
# * https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=81697
# * https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=291177
# * https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=118787
# * https://packages.ubuntu.com/source/bionic/dh-sysuser
# * https://packages.ubuntu.com/bionic/dh-sysuser
# * https://packages.ubuntu.com/bionic/sysuser-helper
# * https://medium.com/opsops/dh-sysuser-6bd3e3d623dd
# * https://www.debian.org/doc/debian-policy/ch-maintainerscripts.html

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

#################
# SYSUSER BEGIN #
#################

# The section "Automatically added by dh_systemd_start" (re)starts the
# service which requires a sysuser. Add the sysuser first.
if [ "configure" = "$1" ]; then
    export CONF_HOME='/nonexistent'
    export CONF_USERNAME="@('-'.join(Package.split('-')[2:])[:32])"
    if ! getent passwd "$CONF_USERNAME"; then
        emptydir=$(mktemp -d) # to inhibit /etc/skel
        set -- --system --shell /usr/sbin/nologin
        # Create home directory for system user, unless it is /nonexistent,
        # which must stay nonexistent.
        if [ "${CONF_HOME}" != '/nonexistent' ]; then
            set -- "$*" --create-home --skel "${emptydir}" --home-dir "${CONF_HOME}"
        fi
        useradd $* "${CONF_USERNAME}"
        rmdir "${emptydir}"
    fi
    # If user already have another home directory, we use `usermod
    # --move-home'. Unfortunately, new home is required to be non-existent
    # (and different from previous), so this conditional is required.
    if ! [ -d "${CONF_HOME}" ]; then
        usermod --move-home --home "$CONF_HOME" "$CONF_USERNAME"
    fi
fi

###############
# SYSUSER END #
###############

################################################################################

#DEBHELPER#

################################################################################

##############
# UDEV BEGIN #
##############

# The section "Automatically added by dh_installudev" attempts to preserve user
# changes to udev rules under /etc/udev/rules.d. Bounce udev after that
if [ "$1" = "configure" ]; then
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
fi
############
# UDEV END #
############

exit 0
