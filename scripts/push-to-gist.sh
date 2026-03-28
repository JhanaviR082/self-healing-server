#!/bin/bash

# ============================================
# DUAL STORAGE SCRIPT
# ============================================

GITHUB_TOKEN="YOUR_GITHUB_TOKEN_HERE"
GIST_ID="e4ec5ee522b0b5f2872d86f8adab8100"

# Get metrics
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)
[ -z "$CPU" ] && CPU=0

MEM_TOTAL=$(free | grep Mem | awk '{print $2}')
MEM_USED=$(free | grep Mem | awk '{print $3}')
MEM=$((MEM_USED * 100 / MEM_TOTAL))

DISK=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
UPTIME=$(uptime -p)
NGINX=$(systemctl is-active nginx)
CRON=$(crontab -l 2>/dev/null | grep -q "nginx-health-check" && echo "active" || echo "inactive")
RUNNER=$([ -f ~/actions-runner/.runner ] && echo "online" || echo "offline")
EMAIL=$([ -f /etc/postfix/sasl_passwd ] && echo "configured" || echo "not configured")
TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S+05:30")

# Create JSON
cat > /tmp/metrics.json << EOF
{
  "current": {
    "timestamp": "$TIMESTAMP",
    "cpu": $CPU,
    "memory": $MEM,
    "disk": $DISK,
    "nginx": "$NGINX",
    "cron": "$CRON",
    "runner": "$RUNNER",
    "email": "$EMAIL",
    "uptime": "$UPTIME"
  }
}
EOF

# Push to Gist
curl -s -X PATCH \
    -H "Authorization: token $GITHUB_TOKEN" \
    -d "{\"files\":{\"metrics.json\":{\"content\":$(jq -Rs . /tmp/metrics.json)}}}" \
    https://api.github.com/gists/$GIST_ID

echo "[$(date)] Metrics pushed"
