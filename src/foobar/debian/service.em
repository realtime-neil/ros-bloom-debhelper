# ros-init-mwe/src/foobar/debian/service.em

[Unit]
Description=foobar
After=network.target

[Service]
EnvironmentFile=@(InstallationPrefix)/setup.sh
ExecStart=@(InstallationPrefix)/bin/@(Name)

[Install]
WantedBy=default.target
