# 🛡️ Self-Healing Server

> A production-grade self-healing Linux server with automated recovery, real-time monitoring, and CI/CD pipeline.

---

## 📋 Table of Contents
- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Data Flow](#-data-flow)
- [Self-Healing Mechanism](#-self-healing-mechanism)
- [Tech Stack](#-tech-stack)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Future Improvements](#-future-improvements)
- [License](#-license)
- [Contact](#-contact)

---
## 🎯 Overview

This project implements a **self-healing Linux server** that automatically detects and recovers from failures, sends real-time alerts, and provides a live monitoring dashboard. It's designed to minimize downtime and reduce manual intervention — exactly how modern cloud infrastructure operates.

### Key Capabilities

| Capability | Description |
|------------|-------------|
| 🔄 **Auto-restart** | Detects Nginx crashes within 60 seconds and restarts automatically |
| 📧 **Email alerts** | Sends detailed alerts with system metrics when failures occur |
| 🚀 **CI/CD pipeline** | Push to GitHub → auto-deploy to server via self-hosted runner |
| 📊 **Live dashboard** | Real-time metrics, historical graphs, crash alerts, deployment history |
| 💾 **Dual storage** | Local files for fast access + GitHub Gist backup for offline viewing |
| 🏗️ **Infrastructure as Code** | Single `setup.sh` script rebuilds entire server from scratch |

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| **Self-Healing** | Monitors Nginx every minute, auto-restarts on failure |
| **Email Alerts** | Sends detailed email with CPU/Memory/Disk metrics when crash occurs |
| **CI/CD Pipeline** | Push to GitHub → auto-deploy to VM via self-hosted runner |
| **Live Dashboard** | Real-time metrics, historical graphs, crash alerts, deployment history, live logs |
| **Dual Storage** | Local files (fast) + GitHub Gist backup (offline access) |
| **Infrastructure as Code** | Single `setup.sh` script rebuilds entire server from scratch |

---
## 🏗️ Architecture

### System Overview

```mermaid
graph TB
    subgraph USER["👤 User Browser"]
        U[Mac Browser]
    end

    subgraph VIRTUALBOX["🖥️ VirtualBox"]
        PF[Port Forwarding<br/>localhost:8080 → VM:80]
    end

    subgraph VM["☁️ Ubuntu Server VM"]
        NGINX[Nginx Server<br/>Port 80]
        
        subgraph WEB["Web Files"]
            INDEX[index.html<br/>Website]
            DASH[dashboard.html<br/>Monitoring UI]
            JSON["JSON Files<br/>current.json · history.json<br/>alerts.json · deploys.json"]
        end
        
        subgraph SCRIPTS["Automation Scripts"]
            HEALTH[nginx-health-check.sh<br/>Self-Healing · Every Minute]
            PUSH[push-to-gist.sh<br/>Dual Storage · Every 2 Minutes]
            DEPLOY[deploy-from-github.sh<br/>CI/CD Deployment]
        end
        
        subgraph SERVICES["System Services"]
            CRON[Cron Scheduler]
            RUNNER[GitHub Self-Hosted Runner]
            POSTFIX[Postfix Email]
        end
        
        subgraph LOGS["Log Files"]
            HEALTH_LOG[/var/log/nginx-health.log]
            DEPLOY_LOG[/var/log/deploy.log]
        end
    end

    subgraph CLOUD["☁️ Cloud Backup"]
        GIST[GitHub Gist<br/>metrics.json]
        ACTIONS[GitHub Actions]
    end

    U -->|http://localhost:8080| PF
    PF --> NGINX
    NGINX --> INDEX
    NGINX --> DASH
    NGINX --> JSON
    
    CRON --> HEALTH
    CRON --> PUSH
    RUNNER --> DEPLOY
    
    HEALTH --> HEALTH_LOG
    HEALTH -->|Email Alert| POSTFIX
    HEALTH --> JSON
    
    PUSH --> JSON
    PUSH -->|Backup| GIST
    
    DEPLOY --> DEPLOY_LOG
    DEPLOY -->|Updates| INDEX
    DEPLOY -->|Updates| DASH
    
    ACTIONS -->|Triggers| RUNNER
    
    DASH -->|Fetches JSON every 10s| JSON
    DASH -->|Fallback when VM off| GIST

    style U fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff
    style NGINX fill:#2196F3,stroke:#0b5e7e,stroke-width:2px,color:#fff
    style HEALTH fill:#FF9800,stroke:#e65100,stroke-width:2px,color:#fff
    style GIST fill:#9C27B0,stroke:#6a1b9a,stroke-width:2px,color:#fff
```
## 🔄 CI/CD Pipeline

```mermaid
flowchart LR
    subgraph DEV["💻 Developer (Mac)"]
        A[Edit Code] --> B[git add .]
        B --> C[git commit]
        C --> D[git push]
    end

    subgraph GITHUB["🐙 GitHub"]
        E[Repository<br/>self-healing-server] --> F[GitHub Actions]
        F --> G[CI: Test Job<br/>Ubuntu Latest]
        G --> H{HTML Valid?}
        H -->|No| I[❌ Fail Pipeline]
        H -->|Yes| J[✅ Proceed]
    end

    subgraph VM["🖥️ Self-Hosted Runner (VM)"]
        J --> K[CD: Deploy Job]
        K --> L[Checkout Code]
        L --> M[Copy files to<br/>/var/www/html/]
        M --> N[Reload Nginx]
        N --> O[Log to<br/>/var/log/deploy.log]
    end

    subgraph DASH["📊 Dashboard"]
        O --> P[Dashboard Shows<br/>Deployment History]
        M --> Q[Website Updated]
    end

    style A fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff
    style F fill:#24292e,stroke:#000,stroke-width:2px,color:#fff
    style K fill:#FF9800,stroke:#e65100,stroke-width:2px,color:#fff
    style O fill:#2196F3,stroke:#0b5e7e,stroke-width:2px,color:#fff
```
## 📊 Data Flow

```mermaid
flowchart TB
    subgraph COLLECTION["📈 Data Collection (Every 2 Minutes)"]
        PUSH[push-to-gist.sh]
        METRICS[Collect Metrics:<br/>CPU · Memory · Disk<br/>Nginx · Cron · Runner · Email<br/>Uptime]
    end

    subgraph LOCAL["💾 Local Storage (Primary)"]
        direction LR
        CURR[current.json<br/>Live Metrics]
        HIST[history.json<br/>500 Points History]
        ALERTS[alerts.json<br/>Crash Events]
        DEPLOYS[deploys.json<br/>Deployments]
    end

    subgraph BACKUP["☁️ Cloud Backup (GitHub Gist)"]
        GIST[metrics.json<br/>Same as local<br/>Accessible when VM off]
    end

    subgraph DASH["📊 Dashboard (Every 10 Seconds)"]
        HTML[dashboard.html]
        FETCH[fetchWithFallback()]
        DISPLAY{Display Data}
    end

    PUSH --> METRICS
    METRICS --> CURR
    METRICS --> HIST
    METRICS --> ALERTS
    METRICS --> DEPLOYS
    METRICS --> GIST

    HTML --> FETCH
    FETCH -->|Try First| CURR
    FETCH -->|If VM ON| DISPLAY
    FETCH -->|If VM OFF| GIST
    GIST -->|Fallback| DISPLAY

    style PUSH fill:#FF9800,stroke:#e65100,stroke-width:2px,color:#fff
    style GIST fill:#9C27B0,stroke:#6a1b9a,stroke-width:2px,color:#fff
    style HTML fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff
```
## ⚙️ Self-Healing Mechanism

```mermaid
flowchart TD
    START([Cron: Every Minute]) --> SCRIPT[/usr/local/bin/nginx-health-check.sh]

    SCRIPT --> CHECK{curl -I -s http://localhost<br/>grep -q "200 OK"}

    CHECK -->|✅ Yes - Healthy| HEALTHY[Log: Nginx is healthy]
    HEALTHY --> END([End])

    CHECK -->|❌ No - Crash| DOWN[Log: Nginx is down! RESTARTING...]

    DOWN --> METRICS[Collect System Metrics<br/>CPU · Memory · Disk · Uptime]

    METRICS --> EMAIL[Send Professional Email Alert<br/>To: jhanavi020@gmail.com<br/>Subject: 🚨 Server Alert<br/>Body: Metrics + Recovery Report]

    EMAIL --> RESTART[systemctl restart nginx]

    RESTART --> VERIFY{Verify Restart Success?}

    VERIFY -->|Yes| SUCCESS[Log: Restart completed!]
    VERIFY -->|No| FAIL[Log: Restart FAILED!]

    SUCCESS --> UPDATE[Update JSON Files:<br/>alerts.json · history.json]

    UPDATE --> DASH[Dashboard Shows Recovery<br/>Recent Alerts + Live Logs]

    DASH --> END

    FAIL --> ALERT[Send Failure Alert Email]
    ALERT --> END

    style CHECK fill:#FF9800,stroke:#e65100,stroke-width:2px,color:#fff
    style EMAIL fill:#f44336,stroke:#c62828,stroke-width:2px,color:#fff
    style RESTART fill:#4CAF50,stroke:#2E7D32,stroke-width:2px,color:#fff
    style DASH fill:#2196F3,stroke:#0b5e7e,stroke-width:2px,color:#fff
```
## 🛠️ Tech Stack

| Category | Technology | Purpose |
|----------|------------|---------|
| **Operating System** | Ubuntu Server 24.04 | Base OS for VM |
| **Web Server** | Nginx | Serves website and dashboard |
| **Automation** | Bash Scripts | Self-healing, data collection, deployment |
| **Scheduling** | Cron | Runs health checks every minute |
| **CI/CD** | GitHub Actions + Self-hosted Runner | Automated deployments |
| **Email** | Postfix + Gmail SMTP | Alert notifications |
| **Frontend** | HTML/CSS/JS + Chart.js | Live monitoring dashboard |
| **Storage** | Local JSON + GitHub Gist | Dual storage for metrics |
| **Infrastructure as Code** | Bash (`setup.sh`) | One-command rebuild |
| **Virtualization** | VirtualBox | VM with NAT + port forwarding |

---
## 🚀 Quick Start

### Prerequisites
- VirtualBox installed on your Mac
- GitHub account
- Gmail account (for email alerts)

### One-Command Setup

```bash
# Clone the repository
git clone https://github.com/JhanaviR082/self-healing-server.git
cd self-healing-server

# Copy files to a fresh Ubuntu VM and run
./setup.sh
```

### Manual Verification

```bash
# SSH into your VM
ssh -p 2222 jhanavi@localhost

# Verify services
sudo systemctl status nginx
crontab -l
cd ~/actions-runner && sudo ./svc.sh status

# View live logs
tail -f /var/log/nginx-health.log
```

### Test Self-Healing

```bash
# Simulate a crash
sudo systemctl stop nginx

# Watch logs for recovery (within 60 seconds)
tail -f /var/log/nginx-health.log

# Check your email for alert
```

### Test CI/CD

```bash
# Make a change
echo "<!-- test -->" >> index.html

# Push to GitHub
git add index.html
git commit -m "Test deployment"
git push

# Watch dashboard for deployment history
```

---
## 📁 Project Structure

```
self-healing-server/
├── .github/workflows/
│   └── deploy.yml              # CI/CD pipeline
├── screenshots/                 # Documentation images
│   ├── dashboard-live.png
│   ├── dashboard-offline.png
│   ├── health-check-log.png
│   └── ...
├── dashboard.html              # Monitoring dashboard
├── index.html                  # Website
├── setup.sh                    # Infrastructure as Code
└── README.md                   # Documentation

Your VM (/var/www/html/)
├── index.html                  # Website (served)
├── dashboard.html              # Dashboard (served)
├── current.json                # Live metrics
├── history.json                # Historical data (500 points)
├── alerts.json                 # Crash alerts
└── deploys.json                # Deployment history

Your VM (/usr/local/bin/)
├── nginx-health-check.sh       # Self-healing script
├── push-to-gist.sh             # Dual storage script
└── deploy-from-github.sh       # Deployment script

Your VM (/var/log/)
├── nginx-health.log            # Health check logs
└── deploy.log                  # Deployment logs
```

---
## 🔮 Future Improvements

- [ ] **GitHub App Authentication** — Auto-renewing tokens (no expiration)
- [ ] **Multi-Server Support** — Monitor multiple VMs from one dashboard
- [ ] **Slack/Discord Integration** — Send alerts to chat
- [ ] **Prometheus Exporter** — Industry-standard metrics endpoint
- [ ] **Predictive Analytics** — AI-based failure prediction
- [ ] **Mobile App / PWA** — Installable dashboard on phone
- [ ] **Ansible Playbook** — Infrastructure as Code with Ansible

---

## 📄 License

This project is open source and available under the MIT License.

---
*Built to demonstrate DevOps, SRE, and Cloud Engineering skills.*
