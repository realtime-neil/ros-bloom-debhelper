# ros-bloom-debhelper/src/my_project/debian/service.em

[Unit]
Description=@(Description)
After=network.target

[Service]
EnvironmentFile=@(InstallationPrefix)/setup.sh
ExecStart=@(InstallationPrefix)/bin/@(Name.replace('_','-'))

[Install]
WantedBy=default.target
