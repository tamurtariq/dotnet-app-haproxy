# 🧪 .NET App Deployment with HAProxy (Multi-Server Setup)

This project provides a fully automated deployment script that sets up a high-availability load-balanced environment for your ASP.NET Core application using **HAProxy** as the load balancer and **multiple .NET web servers**.

Whether you want to test load balancing or deploy a real app, this script will install all necessary dependencies, create or clone your .NET project, and configure HAProxy to distribute traffic across the web servers.

---

## 🚀 Features

- Deploys a sample or custom ASP.NET Core app.
- Supports **multiple web servers** for backend.
- Installs and configures **HAProxy** as the frontend load balancer.
- Automatically sets up a systemd service to run the app.
- Enables HAProxy **stats dashboard** for monitoring.
- Fully automated with **SSH access**.
- Error handling & validation for robust setup.

---

## 📋 Requirements

Run this script on a fresh Ubuntu VM that will act as the **HAProxy load balancer**. You must have:

- SSH access to all your web servers (public/private IP)
- Ubuntu (20.04+ recommended) on all nodes
- A domain name pointing to your load balancer (optional but recommended)

---

## 🛠️ Installation

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/dotnet-ha-deploy.git
cd dotnet-ha-deploy

```

### 2. Make the Script Executable
```bash
chmod +x deploy_dotnet_haproxy.sh
```
### 3. Run the Script
```bash

./deploy_dotnet_haproxy.sh
```
🧑‍💻 Script Walkthrough
The script will prompt you for:

Domain name (e.g., example.com)

Project name (will be used for folder and service naming)

Number of web servers

For each web server:

IP address

SSH username

SSH password

What Happens Behind the Scenes:
HAProxy is installed and configured with port 80 for HTTP

A sample ASP.NET Core app is created or code is cloned if desired

App is published to /var/www/<project_name> on each web server

A systemd service is created and started

HAProxy is set up to forward traffic to backend web servers in a round-robin fashion

HAProxy stats dashboard enabled at http://<domain>:8404 (default credentials: admin:admin)

📦 Directory Structure on Web Servers
php-template
```bash
/var/www/<project_name>/
├── <project_name>.dll
├── wwwroot/
└── ...
```

Systemd service file is placed at:

swift

/etc/systemd/system/<project_name>.service
## 📊 HAProxy Stats Dashboard
Once deployed, view HAProxy stats at:

```arduino

http://<your-domain>:8404/stats
```
Username: admin

Password: admin

🧪 Testing Access
After deployment, you should be able to access your app using:

```cpp

http://<your-domain>/
```
Each web server will respond with a unique message (based on its IP) so you can verify load balancing.

## 🔐 SSL Support (Future Scope)
You can enhance this setup by adding an Nginx reverse proxy with SSL termination in front of HAProxy or configure HAProxy for SSL directly.

## 📌 Notes
This script is intended for test environments and dev setups.

For production, consider hardening SSH, using SSH keys instead of passwords, setting firewall rules, and using Let's Encrypt for SSL.

## 🧑‍🏫 Contributing
Want to improve this or add Nginx SSL termination? Fork the repo and create a pull request!

## 📄 License
MIT License – feel free to use, modify, and share!

## 🙌 Acknowledgments
Inspired by developers who want to quickly spin up test environments and validate HAProxy load balancing for .NET apps.