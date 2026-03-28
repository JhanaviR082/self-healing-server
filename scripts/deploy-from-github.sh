#!/bin/bash

LOG="/var/log/deploy.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
WEB_DIR="/var/www/html"

echo "[$DATE] 🚀 Deployment started" >> $LOG

cd $WEB_DIR

# Pull latest changes
sudo git pull origin main >> $LOG 2>&1

if [ $? -eq 0 ]; then
    echo "[$DATE] ✅ Deployment completed successfully" >> $LOG
else
    echo "[$DATE] ❌ Deployment failed" >> $LOG
fi

sudo systemctl reload nginx
