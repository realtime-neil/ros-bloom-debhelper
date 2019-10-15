#!/bin/sh

# /etc/cron.hourly/@(Package)

# every hour, find and delete any and all ros things; this cron script assumes
# ROS_HOME="/tmp/@(Name)"

set -eu

find "/tmp/@(Name)" -mindepth 1 -delete
