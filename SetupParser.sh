#!/bin/bash

nparse=/usr/lib/nethogs-parser
nlog=/opt/netlog
logdir=/var/log/netlog
bpath=/usr/bin
cnf=/etc/logrotate.d/netlog

# Install dependencies
apt-get update
apt-get install golang-go -y

# Create files and directories
if [ ! -f $bpath/netlog-parser ]; then
    echo "Setting up netlog..."
    mkdir -p $nparse 
    cp nethogs-parser/hogs.go $nparse
    
    cat > $bpath/netlog-parser << EOF
#!/bin/bash

echo -e "\\n"
printf " _   _      _   _             \\n| \\ | |    | | | |            \\n|  \\| | ___| |_| | ___   __ _ \\n| . ' |/ _ \\ __| |/ _ \\ / _' |\\n| |\\  |  __/ |_| | (_) | (_| |\\n\\_| \\_/\\___|\\__|_|\\___/ \\__, |\\n                         __/ |\\n                        |___/ \\n\\n"
echo "Data is available for:"
printf "\n"

files=\$(ls -I "*.gz" \$1)

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
                go run /usr/lib/nethogs-parser/hogs.go -type=pretty $1/\${file[\$input]}
                break
        fi
done
EOF
    chmod +x $bpath/netlog-parser
fi

exit 0
