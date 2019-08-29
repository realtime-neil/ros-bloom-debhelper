#!/bin/sh

# /etc/cron.daily/@(Package)
#
# This is a cron script file generated via bloom from the following template:
#
# ros-bloom-debhelper/src/my_project/debian/cron.daily.em

readonly service="@(Package)"
if ! systemctl is-active --quiet "${service}"; then
    systemctl start "${service}"
fi
