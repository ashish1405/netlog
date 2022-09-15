#!/bin/bash

nlog=/opt/netlog
logdir=/var/log/netlog
bpath=/usr/bin
cnf=/etc/logrotate.d/netlog

# Install dependencies
apt-get update
#apt-get install nethogs golang-go -y
apt-get install nethogs -y

# Create files and directories
if [ ! -d $nlog ]; then
    echo "Setting up netlog..."
    mkdir -p $nlog $logdir
    cat > $nlog/netlog << EOF
#!/bin/bash
nethogs -t | tee -a /var/log/netlog/daily /var/log/netlog/monthly
EOF
    
    chmod +x $nlog/netlog
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
dateext
create
postrotate
        systemctl restart netlog
endscript
}

/var/log/netlog/monthly {
monthly
rotate 3
compress
dateext
create
postrotate
        systemctl restart netlog
endscript
}
EOF
fi

exit 0
