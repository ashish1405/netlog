#!/bin/bash

nparse=/usr/lib/nethogs-parser
nlog=/opt/netlog
logdir=/var/log/netlog
bpath=/usr/bin
cnf=/etc/logrotate.d/netlog

# Install dependencies
apt-get update
apt-get install nethogs golang-go -y

# Create files and directories
if [ ! -d $nlog ]; then
    echo "Setting up netlog..."
    mkdir -p $nparse $nlog $logdir
    cp nethogs-parser/hogs.go $nparse
    cat > $nlog/netlog << EOF
#!/bin/bash
nethogs -d 60 -t | tee -a /var/log/netlog/daily /var/log/netlog/monthly
EOF
    cat > $bpath/netlog-parser << EOF
#!/bin/bash
printf "Data is available for:\n"

wdir=$(pwd)

cd /var/log/netlog/
ls -1
read -e -p "Select the day/month: " file

cd $wdir

printf "\n"
go run /usr/lib/nethogs-parser/hogs.go -type=pretty /var/log/netlog/$file | grep -v root
EOF
    chmod +x $nlog/netlog
    chmod +x $bpath/netlog-parser
    chmod 775 $logdir
fi

echo "Setting up netlog service..."
IS_ACTIVE=$(sudo systemctl is-active netlog)
if [ "$IS_ACTIVE" == "active" ]; then
    # Restart netlog service if active
    echo "Service is running"
    echo "Restarting service..."
    systemctl restart netlog
    echo "Service has restarted"
else
    # Create the netlog service file
    echo "Creating service file"
    cat > /etc/systemd/system/netlog.service << EOF
[Unit]
Description=Netlog Nethogs daemon
After=network.target

[Service]
Type=simple
Restart=on-failure
User=root
ExecStart=/opt/netlog/netlog

[Install]
WantedBy=multi-user.target
EOF
    # Enable and start the netlog service
    echo "Enabling the netlog service..."
    systemctl daemon-reload
    systemctl enable netlog
    systemctl start netlog
    echo "Netlog service started!"
fi

# Setup log rotation
if [ ! -f $cnf ]; then
    cat > $cnf << EOF
/var/log/netlog/daily {
daily
rotate 30
create
postrotate
        systemctl restart netlog
endscript
}

/var/log/netlog/monthly {
monthly
rotate 3
compress
create
postrotate
        systemctl restart netlog
endscript
}
EOF
fi

exit 0
