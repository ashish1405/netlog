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

echo -e "\\n"
printf " _   _      _   _             \\n| \\ | |    | | | |            \\n|  \\| | ___| |_| | ___   __ _ \\n| . ' |/ _ \\ __| |/ _ \\ / _' |\\n| |\\  |  __/ |_| | (_) | (_| |\\n\\_| \\_/\\___|\\__|_|\\___/ \\__, |\\n                         __/ |\\n                        |___/ \\n\\n"
echo "Data is available for:"
printf "\n"

files=\$(ls -I "*.gz" /var/log/netlog/)

while true; do
        i=1

        for j in \$files
        do
        echo "\$i. \$j"
        file[i]=\$j
        i=\$(( i + 1 ))
        done

        printf "\n"
        echo "Enter number or 0 to exit:"
        read input

        number=\$(printf '%s\\n' "\$input" | tr -dc '[:digit:]')

        if [ "\$number" == "0" ]; then
                printf "\\n"
                exit
        elif [ -z \$number ]; then
                printf "\\n"
                echo "No value selected"
                printf "\\n"
        elif [ "\$number" -gt "\$i" ]; then
                printf "\\n"
                echo "Invalid selection"
                printf "\\n"
        else
                printf "\\n"
                go run /usr/lib/nethogs-parser/hogs.go -type=pretty /var/log/netlog/\${file[\$input]}
                break
        fi
done
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
