#!/bin/bash
set -e
trap 'echo "❌ Error on line $LINENO"' ERR

echo "=========================================="
echo " Setting up Self-Healing Server...."
echo "=========================================="

# ============================================
# PART 1: SYSTEM UPDATE
# ============================================
echo "📦 Updating system..."
sudo apt update && sudo apt upgrade -y

# ============================================
# PART 2: INSTALL DEPENDENCIES
# ============================================
echo "📦 Installing dependencies..."
sudo apt install -y nginx curl wget git mailutils

# ============================================
# PART 3: DEPLOY WEBSITE FILES
# ============================================
echo "📄 Deploying website files..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo mkdir -p /var/www/html

if [ -f "$SCRIPT_DIR/index.html" ]; then
    sudo cp "$SCRIPT_DIR/index.html" /var/www/html/
    echo "✅ Copied index.html from project folder"
else
    echo "⚠️  Creating default index.html..."
    sudo tee /var/www/html/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Self-Healing Server</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; background: #1a1a2e; color: #eee; }
        h1 { color: #00ff88; }
        .status { background: #00aa44; display: inline-block; padding: 10px 20px; border-radius: 20px; margin: 20px 0; }
    </style>
</head>
<body>
    <h1>🛡️ Self-Healing Server Active!</h1>
    <div class="status">✅ System Healthy</div>
    <p>Nginx is running and auto-healing is enabled.</p>
    <p>Last updated: <span id="time"></span></p>
    <script>document.getElementById('time').innerText = new Date().toLocaleString();</script>
</body>
</html>
EOF
    echo "✅ Default index.html created"
fi

# ============================================
# PART 4: START NGINX
# ============================================
echo "🌐 Configuring Nginx..."
sudo systemctl enable nginx
sudo systemctl start nginx

# ============================================
# PART 5: CREATE HEALTH CHECK SCRIPT
# ============================================
echo "🩺 Creating health check script..."
sudo tee /usr/local/bin/nginx-health-check.sh > /dev/null << 'EOF'
#!/bin/bash
LOG="/var/log/nginx-health.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
if curl -I -s http://localhost | grep -q "200 OK"; then 
    echo "[$DATE] ✅ Nginx is healthy" >> $LOG
else 
    echo "[$DATE] ❌ Nginx is down! RESTARTING..." >> $LOG
    echo "[$DATE] Nginx crashed and was restarted" | mail -s "⚠️ Server Alert" -a "From: Self-Healing Server <jhanavi020@gmail.com>" "jhanavi020@gmail.com"
    systemctl restart nginx
    echo "[$DATE] ✅ Restart completed!" >> $LOG
fi
EOF

sudo chmod +x /usr/local/bin/nginx-health-check.sh
echo "✅ Health check script created"

# ============================================
# PART 6: CREATE LOG FILE
# ============================================
echo "📝 Creating log file..."
sudo touch /var/log/nginx-health.log
sudo chmod 666 /var/log/nginx-health.log

# ============================================
# PART 7: SETUP CRON
# ============================================
echo "⏰ Setting up cron..."
(crontab -l 2>/dev/null | grep -v "nginx-health-check.sh"; echo "* * * * * /usr/local/bin/nginx-health-check.sh") | crontab -
echo "✅ Cron configured (runs every minute)"

# ============================================
# PART 8: SETUP EMAIL (GMAIL SMTP)
# ============================================
echo "📧 Configuring email alerts..."

# Configure Postfix only if not already configured
if ! grep -q "relayhost = \[smtp.gmail.com\]:587" /etc/postfix/main.cf 2>/dev/null; then
    sudo tee -a /etc/postfix/main.cf > /dev/null << 'EOF'

# Gmail SMTP Configuration (added by setup script)
relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtp_sasl_security_options = noanonymous
EOF
    echo "✅ Postfix configured"
fi

# Ask for credentials
read -p "Enter your Gmail address: " GMAIL
read -sp "Enter your Gmail App Password (16 chars, no spaces): " PASS
echo ""

# Create password file
echo "[smtp.gmail.com]:587 $GMAIL:$PASS" | sudo tee /etc/postfix/sasl_passwd > /dev/null

# Secure and apply
sudo chmod 600 /etc/postfix/sasl_passwd
sudo postmap /etc/postfix/sasl_passwd
sudo systemctl restart postfix
echo "✅ Email configured"

# Send test email
echo "📧 Sending test email..."
echo "Self-healing server setup completed on $(date)" | mail -s "✅ Server Setup Complete" -a "From: Self-Healing Server <$GMAIL>" "$GMAIL"
echo "✅ Test email sent to $GMAIL"

# ============================================
# PART 9: SETUP FIREWALL
# ============================================
echo "🔒 Configuring firewall..."
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
echo "y" | sudo ufw enable
echo "✅ Firewall configured (SSH and HTTP allowed)"

# ============================================
# PART 10: SETUP GITHUB ACTIONS RUNNER
# ============================================
echo "🏃 Setting up GitHub Actions runner..."
read -p "Enter GitHub runner token (from https://github.com/JhanaviR082/self-healing-server/settings/actions/runners/new): " RUNNER_TOKEN

cd ~
mkdir -p actions-runner
cd actions-runner

# Download runner (using latest stable version)
curl -o actions-runner-linux-x64.tar.gz -L https://github.com/actions/runner/releases/download/v2.322.0/actions-runner-linux-x64-2.322.0.tar.gz
tar xzf actions-runner-linux-x64.tar.gz

# Configure
./config.sh --url https://github.com/JhanaviR082/self-healing-server --token $RUNNER_TOKEN --unattended --name self-healing-vm

# Install as service
sudo ./svc.sh install
sudo ./svc.sh start
echo "✅ GitHub Actions runner configured and started"

cd ~/self-healing-server

# ============================================
# PART 11: FINAL
# ============================================
echo ""
echo "=========================================="
echo "✅ SETUP COMPLETE!"
echo "=========================================="
echo ""
echo "🌐 Website: http://localhost:8080"
echo "📋 Check logs: sudo tail -f /var/log/nginx-health.log"
echo "🔧 Test failure: sudo systemctl stop nginx"
echo "📧 Check email for setup confirmation"
echo ""
echo "=========================================="
