#!/bin/sh
#
# Get current usage of a particular partition, probably /opt, send it to slack webhook
#
source /opt/.deploy-meza/config.sh

if [ -z "$slack_webhook_token_disk_usage" ]; then
	slack_token=""
else
	slack_token="$slack_webhook_token_disk_usage"
fi

# If no channel in config, don't specify one in ansible-slack call, thus using
# webhook default channel
if [ -z "$slack_channel_disk_usage" ]; then
	slack_channel=""
else
	slack_channel="channel=#$slack_channel_disk_usage"
fi

# Slack username
if [ ! -z "$slack_username_disk_usage" ]; then
	slack_username="$slack_username_disk_usage"
else
	slack_username="Meza disk space monitor"
fi

# If we don't have a disk mount to check, don't do anything. If this is the
# case then this script shouldn't be running in the first place. Thus, exit
# with error code.
if [ -z "$disk_space_usage_mount_name" ]; then
	exit 1;
fi

# If no better descriptor given, just call it "disk"
if [ -z "$disk_space_usage_mount_short_name" ]; then
	disk_space_usage_mount_short_name="Disk"
fi

# get all the dataz
datetime=$(date "+%Y%m%d%H%M%S")
dayofweek=$(date +%u)
hour=$(date +%H)
minute=$(date +%M)
mount_name="$disk_space_usage_mount_name"
short_name="$disk_space_usage_mount_short_name"
space_total=`df | grep "$mount_name" | awk '{print $2;}'`
space_used=`df | grep "$mount_name" | awk '{print $3;}'`
space_remain=`df | grep "$mount_name" | awk '{print $4;}'`
space_used_percent=`df | grep "$mount_name" | awk '{print $5;}'`

# add data point to database
insert_sql=`cat <<EOF
	INSERT INTO meza_server_log.disk_space
	(
		datetime,
		space_total,
		space_used
	)
	VALUES
	(
		'$datetime',
		$space_total,
		$space_used
	);
EOF`

# add data point to database
sudo -u root mysql -e"$insert_sql"

# Create Slack message
msg="$short_name usage: $space_used of $space_total KB\n\t$space_used_percent used\n\t$space_remain KB remain"

# Send Slack message, if token set up
if [ $slack_token ]; then

	ansible localhost -m slack -a \
		"token=$slack_token $slack_channel \
		msg='$msg' \
		username='$slack_username' \
		icon_url=https://github.com/enterprisemediawiki/meza/raw/master/src/roles/configure-wiki/files/logo.png \
		link_names=1 \
		color=good"

fi
