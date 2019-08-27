# ros-init-mwe/src/foobar/debian/service.em

[Unit]
Description=foobar
After=network.target

[Service]
EnvironmentFile=@(InstallationPrefix)/setup.sh
ExecStart=/bin/sh -c 'find @(InstallationPrefix) -type f -perm /111 -name foobar -exec {} \;'

[Install]
WantedBy=default.target
