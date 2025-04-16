#!/bin/bash

# Deploy .NET App Behind HAProxy with Multiple Web Servers

read -p "Enter domain name (e.g., example.com): " DOMAIN
read -p "Enter project name (e.g., hello-world): " PROJECT_NAME
read -p "Enter number of web servers to deploy: " SERVER_COUNT

WEB_SERVERS=()
for (( i=1; i<=SERVER_COUNT; i++ ))
do
    read -p "Enter IP for web server $i: " IP
    read -p "Enter SSH username for $IP: " USERNAME
    read -s -p "Enter SSH password for $IP: " PASSWORD
    echo
    WEB_SERVERS+=("$IP|$USERNAME|$PASSWORD")
done

# Function to run commands remotely
run_remote() {
    IP="$1"
    USER="$2"
    PASS="$3"
    shift 3
    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no "$USER@$IP" "$@"
}

install_haproxy() {
    echo "[*] Installing HAProxy on load balancer..."
    sudo apt update && sudo apt install -y haproxy || {
        echo "[!] HAProxy installation failed. Please check the system."
        exit 1
    }
}

configure_haproxy() {
    echo "[*] Configuring HAProxy..."

    BACKEND_CONFIG=""
    COUNT=1
    for ENTRY in "${WEB_SERVERS[@]}"; do
        IP=$(echo "$ENTRY" | cut -d "|" -f 1)
        BACKEND_CONFIG+="    server web$COUNT $IP:5000 check\n"
        COUNT=$((COUNT + 1))
    done

    sudo tee /etc/haproxy/haproxy.cfg > /dev/null <<EOF
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    timeout connect 5000
    timeout client  50000
    timeout server  50000

frontend http_front
    bind *:80
    default_backend dotnet_servers

backend dotnet_servers
    balance roundrobin
$BACKEND_CONFIG

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:admin
EOF

    sudo systemctl restart haproxy
    echo "[+] HAProxy configured and restarted."
}

deploy_web_servers() {
    echo "[*] Deploying app to web servers..."
    for ENTRY in "${WEB_SERVERS[@]}"; do
        IP=$(echo "$ENTRY" | cut -d "|" -f 1)
        USER=$(echo "$ENTRY" | cut -d "|" -f 2)
        PASS=$(echo "$ENTRY" | cut -d "|" -f 3)

        echo "[*] Connecting to $IP"

        run_remote "$IP" "$USER" "$PASS" "command -v dotnet || (wget https://dot.net/v1/dotnet-install.sh && chmod +x dotnet-install.sh && ./dotnet-install.sh --runtime aspnetcore --channel 8.0)"
        run_remote "$IP" "$USER" "$PASS" "sudo apt update && sudo apt install -y nginx sshpass unzip"

        run_remote "$IP" "$USER" "$PASS" "mkdir -p ~/projects && cd ~/projects && (test -d $PROJECT_NAME || dotnet new webapp -o $PROJECT_NAME)"
        run_remote "$IP" "$USER" "$PASS" "cd ~/projects/$PROJECT_NAME && sed -i 's/<h1.*/<h1>Hello from $IP<\/h1>/' Pages/Index.cshtml"

        run_remote "$IP" "$USER" "$PASS" "dotnet publish -c Release -o /var/www/$PROJECT_NAME --urls http://0.0.0.0:5000"

        run_remote "$IP" "$USER" "$PASS" "cat <<SERVICE | sudo tee /etc/systemd/system/$PROJECT_NAME.service
[Unit]
Description=$PROJECT_NAME ASP.NET Core Web App
After=network.target

[Service]
WorkingDirectory=/var/www/$PROJECT_NAME
ExecStart=/root/.dotnet/dotnet /var/www/$PROJECT_NAME/$PROJECT_NAME.dll
Restart=always
RestartSec=10
SyslogIdentifier=$PROJECT_NAME
User=root
Environment=DOTNET_ROOT=/root/.dotnet

[Install]
WantedBy=multi-user.target
SERVICE"

        run_remote "$IP" "$USER" "$PASS" "sudo systemctl daemon-reexec && sudo systemctl daemon-reload && sudo systemctl enable $PROJECT_NAME && sudo systemctl start $PROJECT_NAME"
        echo "[+] App deployed on $IP"
    done
}

main() {
    install_haproxy
    deploy_web_servers
    configure_haproxy
    echo -e "\n[✔] Deployment Complete!"
    echo "You can now access your app at http://$DOMAIN"
    echo "HAProxy stats: http://$DOMAIN:8404 (admin:admin)"
}

main
