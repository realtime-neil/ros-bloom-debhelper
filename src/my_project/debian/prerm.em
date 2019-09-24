#!/bin/sh

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

set -euvx

case "$1" in
    remove|upgrade|deconfigure)
        ###########################
        # COPYPASTA SYSUSER BEGIN #
        ###########################
        export CONF_HOME='/nonexistent'
        export CONF_USERNAME="@(Package)"
        # Transition from dh-sysuser=1.3. It did not passed mainainer script
        # arguments to sysuser-helper.
        case ${1:-} in
            remove|abort-install)
                rmdir --ignore-fail-on-non-empty "${CONF_HOME}"
                if ! [ -d "${CONF_HOME}" ] ; then
                    userdel --force "${CONF_USERNAME}"
                fi
                ;;
        esac
        #########################
        # COPYPASTA SYSUSER END #
        #########################
        ;;
    failed-upgrade)
        ;;
    *)
        echo "prerm called with unknown argument \`$1'" >&2
        exit 1
        ;;
esac

#DEBHELPER#

exit 0
