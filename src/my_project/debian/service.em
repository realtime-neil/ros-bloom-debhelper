# /lib/systemd/system/@(Package).service
#
# This is a systemd service unit file generated by bloom from the following
# template:
#
# ros-bloom-debhelper/src/my_project/debian/service.em

[Unit]
Description="@(Description)"
After=network.target

[Service]
User=@(Package[:32])
Environment='ROS_HOME=/tmp/@(Package)'
ExecStart=/bin/sh -c '. @(InstallationPrefix)/setup.sh && roslaunch my_project main.launch'

[Install]
WantedBy=default.target
