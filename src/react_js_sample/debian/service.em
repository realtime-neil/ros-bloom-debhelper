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
SyslogIdentifier=@(Name)

# references:
# * https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Capabilities
# * http://man7.org/linux/man-pages/man7/capabilities.7.html
CapabilityBoundingSet=CAP_SYS_NICE CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_SYS_NICE CAP_NET_BIND_SERVICE

# https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Nice=
Nice=-10

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

# Execute pre and post scripts as root, otherwise it does it as User=
#
# THIS IS DEPRECATED BUT NOT YET REMOVED
# https://github.com/systemd/systemd/pull/10802#issuecomment-439446299
PermissionsStartOnly=true

Environment=STATE_DIRECTORY=/var/lib/@(Name)
Environment=CACHE_DIRECTORY=/var/cache/@(Name)
Environment=LOGS_DIRECTORY=/var/log/@(Name)
Environment=CONFIGURATION_DIRECTORY=/etc/@(Name)

ExecStartPre=/bin/sh -c 'mkdir -vp ${STATE_DIRECTORY}'
ExecStartPre=/bin/sh -c 'mkdir -vp ${CACHE_DIRECTORY}'
ExecStartPre=/bin/sh -c 'mkdir -vp ${LOGS_DIRECTORY}'
ExecStartPre=/bin/sh -c 'mkdir -vp ${CONFIGURATION_DIRECTORY}'

ExecStartPre=/bin/sh -c 'chown -vR $(id -u ${USER}):$(id -g ${USER}) ${STATE_DIRECTORY}'
ExecStartPre=/bin/sh -c 'chown -vR $(id -u ${USER}):$(id -g ${USER}) ${CACHE_DIRECTORY}'
ExecStartPre=/bin/sh -c 'chown -vR $(id -u ${USER}):$(id -g ${USER}) ${LOGS_DIRECTORY}'
ExecStartPre=/bin/sh -c 'chown -vR $(id -u ${USER}):$(id -g ${USER}) ${CONFIGURATION_DIRECTORY}'

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

# In "normal" conditions, `%t/%N` becomes `/run/$NAME`.
# https://www.freedesktop.org/software/systemd/man/systemd.exec.html#WorkingDirectory=
# https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Specifiers
WorkingDirectory=%t/%N

# roscpp logging is... special.
Environment=ROS_HOME=%t/%N/ros-home
ExecStartPre=/bin/sh -c 'rm -vrf ${ROS_HOME}'
ExecStartPre=/bin/sh -c 'mkdir -vp ${ROS_HOME}'
ExecStartPre=/bin/sh -c 'chown -vR $(id -u ${USER}):$(id -g ${USER}) ${ROS_HOME}'

# Do NOT let `roslaunch` try to start the roscore. `roslaunch` is FANTASTICALLY
# HORRIBLE at detecting a running roscore and, in the case of a false negative,
# will happily start multiple roscores. This is great because, in ROS land,
# `roscore` is tacitly assumed to be a host-wide singleton. Running multiple
# roscores is a great way to demonstrate the condition known as "split-brain",
# wherein your roslaunched processes are "up" but can't communicate. Fun times!
#
# https://github.com/ros/ros_comm/issues/1831
# https://wiki.ros.org/action/info/roslaunch?action=diff&rev2=150&rev1=149
ExecStart=/bin/sh -c '. @(InstallationPrefix)/setup.sh && env | sort && roslaunch --wait -v @(Name) main.launch'
ExecStopPost=/bin/sh -c 'rm -vrf ${ROS_HOME}'

# https://www.freedesktop.org/software/systemd/man/systemd-system.conf.html#DefaultStartLimitIntervalSec=
#
# > DefaultStartLimitIntervalSec=, DefaultStartLimitBurst=
# >
# > Configure the default unit start rate limiting, as configured per-service
# > by StartLimitIntervalSec= and StartLimitBurst=. See systemd.service(5) for
# > details on the per-service settings. DefaultStartLimitIntervalSec= defaults
# > to 10s. DefaultStartLimitBurst= defaults to 5.
#
#
# https://www.freedesktop.org/software/systemd/man/systemd.unit.html#StartLimitIntervalSec=interval
#
# > StartLimitIntervalSec=interval, StartLimitBurst=burst
# >
# > Configure unitstart rate limiting. Units which are started more than burst
# > times within an interval time interval are not permitted to start any more.
Restart=always
RestartSec=5

# > core: rename StartLimitInterval= to StartLimitIntervalSec=
#
# https://github.com/systemd/systemd/commit/f0367da7d1a61ad698a55d17b5c28ddce0dc265a#diff-23355de3ac6bfc17cc1269b0de712568
#
# Allow indefinite restarts as long as they don't come at (or faster than) the
# 1/RestartSec frequency as measured over 15 seconds.
StartLimitInterval=14
StartLimitBurst=3

[Install]
WantedBy=default.target
