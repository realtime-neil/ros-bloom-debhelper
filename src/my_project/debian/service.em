# /lib/systemd/system/@(Package).service

[Unit]
Description=@(Description)
After=network.target

[Service]
# Note: Here, where the ROS documentation says "package", it means "catkin
# project". They are _not_ the same.
#
# > The package [sic] name must start with a letter and contain only lowercase
# > alphabetic, numeric or underscore characters. The package [sic] name should
# > be unique within the ROS community. It may differ from the folder name into
# > which it is checked out, but that is not recommended.
#
# -- https://www.ros.org/reps/rep-0140.html#name
#
# > It is usually recommended to only use usernames that begin with a lower
# > case letter or an underscore, followed by lower case letters, digits,
# > underscores, or dashes. They can end with a dollar sign. In regular
# > expression terms: [a-z_][a-z0-9_-]*[$]?
#
# > On Debian, the only constraints are that usernames must neither start with
# > a dash ('-') nor plus ('+') nor tilde ('~') nor contain a colon (':'), a
# > comma (','), or a whitespace (space: ' ', end of line: '\n', tabulation:
# > '\t', etc.). Note that using a slash ('/') may break the default algorithm
# > for the definition of the user's home directory.
#
# > Usernames may only be up to 32 characters long.
#
# -- man 8 useradd
User=@(Name[:32])

# references:
# * https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Capabilities
# * http://man7.org/linux/man-pages/man7/capabilities.7.html
CapabilityBoundingSet=CAP_SYS_NICE
AmbientCapabilities=CAP_SYS_NICE

# https://www.freedesktop.org/software/systemd/man/systemd.exec.html#RuntimeDirectory=
RuntimeDirectory=@(Name)

# systemd version 229 (shipping with Ubuntu Xenial, as of this writing) doesn't
# export the RUNTIME_DIRECTORY env var, so we have to do this:
Environment=RUNTIME_DIRECTORY=/run/@(Name)

# systemd version 229 (shipping with Ubuntu Xenial, as of this writing) doesn't
# have any of the following:
#
#StateDirectory=@(Name)
#CacheDirectory=@(Name)
#LogsDirectory=@(Name)
#ConfigurationDirectory=@(Name)
#
# ...so fake it:

PermissionsStartOnly=true

Environment=STATE_DIRECTORY=/var/lib/@(Name)
Environment=CACHE_DIRECTORY=/var/cache/@(Name)
Environment=LOGS_DIRECTORY=/var/log/@(Name)
Environment=CONFIGURATION_DIRECTORY=/etc/@(Name)

ExecStartPre=/bin/sh -c 'mkdir -vp ${STATE_DIRECTORY}'
ExecStartPre=/bin/sh -c 'mkdir -vp ${CACHE_DIRECTORY}'
ExecStartPre=/bin/sh -c 'mkdir -vp ${LOGS_DIRECTORY}'
ExecStartPre=/bin/sh -c 'mkdir -vp ${CONFIGURATION_DIRECTORY}'

ExecStartPre=/bin/sh -c 'chown -vR ${USER}:${USER} ${STATE_DIRECTORY}'
ExecStartPre=/bin/sh -c 'chown -vR ${USER}:${USER} ${CACHE_DIRECTORY}'
ExecStartPre=/bin/sh -c 'chown -vR ${USER}:${USER} ${LOGS_DIRECTORY}'
ExecStartPre=/bin/sh -c 'chown -vR ${USER}:${USER} ${CONFIGURATION_DIRECTORY}'

# We need to adapt "The Big Five" env vars into forms that can be easily parsed
# by boost program options; i.e., with a $PROJECT prefix. What's more, we need
# to split the difference between several competing specs that dictate names
# for these things. First read these:
#
# * https://www.gnu.org/prep/standards/html_node/Directory-Variables.html
# * https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
# * https://www.freedesktop.org/software/systemd/man/systemd.exec.html#RuntimeDirectory=
# * https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard
#
# Table of Approximal Associations for ficticious Name "foo"
# | systemd                  | xdg                      | gnu
# +----------------------------------------------------------------------------+
# | $RUNTIME_DIRECTORY       | $XDG_RUNTIME_DIR/foo     | $localstatedir/run/foo
# | $STATE_DIRECTORY         | $XDG_CONFIG_HOME/foo     | $localstatedir/lib/foo
# | $CACHE_DIRECTORY         | $XDG_CACHE_HOME/foo      | $localstatedir/cache/foo
# | $LOGS_DIRECTORY          | $XDG_CONFIG_HOME/log/foo | $localstatedir/log/foo
# | $CONFIGURATION_DIRECTORY | $XDG_CONFIG_HOME/foo     | $sysconfdir/foo

# RUNSTATEDIR was added to GNUInstallDirs in cmake v3.9
#
# > RUNSTATEDIR: run-time variable data (LOCALSTATEDIR/run)
#
# -- https://cmake.org/cmake/help/v3.9/module/GNUInstallDirs.html

# This is okay because Ubuntu has symlink /var/run -> /run
Environment=@(Name.upper())_RUNTIME_DIR=/var/run/@(Name)
Environment=@(Name.upper())_STATE_DIR=/var/lib/@(Name)
Environment=@(Name.upper())_CACHE_DIR=/var/cache/@(Name)
Environment=@(Name.upper())_LOGS_DIR=/var/log/@(Name)
Environment=@(Name.upper())_CONFIG_DIR=/etc/@(Name)

# roscpp logging is... special.
Environment=ROS_HOME=/tmp/@(Name)
ExecStartPre=/bin/sh -c 'rm -rf ${ROS_HOME}'
ExecStart=/bin/sh -c '. @(InstallationPrefix)/setup.sh && env | sort && roslaunch @(Name) main.launch'
ExecStopPost=/bin/sh -c 'rm -rf ${ROS_HOME}'

[Install]
WantedBy=default.target
