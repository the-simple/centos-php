#!/bin/bash
set -e
yum update -y;
yum clean all;

chown root:root /etc/cron.d/*;
chmod 644 /etc/cron.d/*;

exec "$@"
