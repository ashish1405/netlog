#!/bin/bash

echo "Removing Netlog..."
if [ -f "/etc/systemd/system/netlog.service" ]; then
    systemctl stop netlog
    systemctl disable netlog
fi
rm -rf /etc/systemd/system/netlog.service
rm -rf /usr/lib/nethogs-parser
rm -rf /opt/netlog
rm -rf /usr/bin/netlog-parser
rm -rf /etc/logrotate.d/netlog
rm -rf /var/log/netlog
echo "Netlog uninstalled successfully!"
