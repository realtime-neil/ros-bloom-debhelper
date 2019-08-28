# /etc/logrotate.d/@(Package)
#
# This is a logrotate config file generated via bloom from the following
# template:
#
# ros-bloom-debhelper/src/my_project/debian/logrotate.em

/var/log/@(Package).log
{
	rotate 7
	daily
	missingok
	notifempty
	delaycompress
	compress
}
