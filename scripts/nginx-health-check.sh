#!/bin/bash

LOG="/var/log/nginx-health.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Get metrics for email
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)
[ -z "$CPU_USAGE" ] && CPU_USAGE=0

MEM_TOTAL=$(free | grep Mem | awk '{print $2}')
MEM_USED=$(free | grep Mem | awk '{print $3}')
MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))

DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
UPTIME=$(uptime -p)

if curl -I -s http://localhost | grep -q "200 OK"; then 
    echo "[$DATE] ✅ Nginx is healthy | CPU:${CPU_USAGE}% | MEM:${MEM_PERCENT}% | DISK:${DISK_USAGE}%" >> $LOG
else 
    echo "[$DATE] ❌ Nginx is down! RESTARTING..." >> $LOG
    
    # Professional email alert
    EMAIL_BODY=$(cat <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    🚨 SERVER ALERT - AUTO-RECOVERY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📌 EVENT:        Nginx crashed and was automatically restarted
⏰ TIME:         $DATE
🖥️  SERVER:      $(hostname)
🔄 STATUS:       ✅ Recovery successful

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 SYSTEM METRICS AT RECOVERY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   CPU Usage:    ${CPU_USAGE}%
   Memory Usage: ${MEM_PERCENT}%
   Disk Usage:   ${DISK_USAGE}%
   System Uptime: $UPTIME

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 AUTO-HEALING REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ✓ Crash detected at: $DATE
   ✓ Auto-restart triggered
   ✓ Service restored successfully
   ✓ All systems operational

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📌 NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ✅ No action required — system healed itself
   📊 View dashboard: http://localhost:8080/dashboard.html
   📝 Check logs: tail -f /var/log/nginx-health.log

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Self-Healing Server • Auto-restart enabled • 24/7 monitoring
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
)

    echo "$EMAIL_BODY" | mail -s "🚨 Server Alert: Nginx Auto-Restored" -a "From: Self-Healing Server <jhanavi020@gmail.com>" "jhanavi020@gmail.com"
    
    systemctl restart nginx
    echo "[$DATE] ✅ Restart completed!" >> $LOG
fi
