#!/bin/sh

# @(Package) postrm script

# This file is an amalgamation of the following package contents:
#
# * dh-make_2.201701_all/usr/share/debhelper/dh_make/debian/prerm.ex
# * dh-sysuser_1.3.1_all/usr/share/debhelper/autoscripts/prerm-sysuser
# * sysuser-helper_1.3.1_all/lib/sysuser-helper/sysuser-helper
#
# They were harvested on 2019.09.24 from an Ubuntu Bionic host via
#
#     $ apt-get download dh-make dh-sysuser sysuser-helper
#
# The dh-make `prerm.ex` is an example file. The other files have been
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
#
# NOTE: This *POST*-removal script is INTENTIONALLY based on the content of the
# referenced *PRE*-removal scripts. The reason is that system services must be
# shut down before the user running them can be removed.

set -eu

# Use a command substitution on a heredoc because `dh_installdeb` apparently
# only substitutes a #TOKEN# at the beginning of a line
#
# -- https://manpages.debian.org/buster/debhelper/dh_installdeb.1.en.html
readonly package=$(
    cat <<EOF
#PACKAGE#
EOF
)

readonly this="$(readlink -f "$0")"
readonly whatami="@(Package).$(basename "${this}")"

readonly systemd_service_file="/lib/systemd/system/@(Package).service"
readonly sysuser_name="@('-'.join(Package.split('-')[2:])[:32])"
readonly sysuser_home="/nonexistent"
readonly udev_rules_file="/lib/udev/rules.d/60-@(Package).rules"

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

case "$1" in
    purge | remove | upgrade | failed-upgrade | abort-install | abort-upgrade | disappear)
        #################
        # SYSUSER BEGIN #
        #################
        case "$1" in
            remove | abort-install)
                if [ -d "${sysuser_home}" ]; then
                    info "deleting sysuser home: ${sysuser_home}"
                    rmdir --ignore-fail-on-non-empty "${sysuser_home}"
                fi
                if ! [ -d "${sysuser_home}" ]; then
                    info "deleting sysuser: ${sysuser_name}"
                    userdel --force "${sysuser_name}" || true
                fi
                ;;
        esac
        ###############
        # SYSUSER END #
        ###############

        ##############
        # UDEV BEGIN #
        ##############

        # todo: figure out a way to detect if this package has a udev rules
        # file and if it was removed (necessitating a udev bounce)
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
        ############
        # UDEV END #
        ############

        ;;
    *)
        die "unknown argument: \"$1\""
        ;;
esac

################################################################################

exit 0
