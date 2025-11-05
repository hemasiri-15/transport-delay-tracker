# 🚍 Public Transport Timetable & Delay Tracker

A comprehensive bash-based monitoring system that processes bus/train timetable data along with real-time delay updates to generate punctuality reports and alerts.

![Project Status](https://img.shields.io/badge/status-active-success.svg)
![Bash](https://img.shields.io/badge/bash-5.0+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Demo](#demo)
- [Architecture](#architecture)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Technologies](#technologies)
- [Screenshots](#screenshots)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

---

## 🎯 Overview

The **Transport Delay Tracker** is an automated monitoring system designed to analyze public transportation punctuality. It ingests schedule data, compares it with real-time arrival information, calculates delays, and generates comprehensive reports with visualizations.

### Purpose

- Monitor transport service reliability
- Identify problematic routes and patterns
- Generate actionable insights for transit authorities
- Provide automated alerts for critical delays
- Maintain historical data for trend analysis

---

## ✨ Features

### Core Functionality

✅ **Data Ingestion**
- CSV timetable parsing
- JSON/API integration for live delay feeds
- Automatic data validation and cleaning

✅ **Delay Analysis**
- Scheduled vs. actual arrival time comparison
- Delay calculation in minutes
- Severity classification (On-Time, Minor, Major, Critical)
- Route-level statistics

✅ **Reporting System**
- **CSV Reports** - Raw data for Excel/analysis
- **HTML Reports** - Interactive dashboards with charts
- **PDF Reports** - Print-ready professional documents

✅ **Visualizations**
- Average delay by route (bar chart)
- On-time performance metrics (bar chart)
- Delay severity distribution (doughnut chart)

✅ **Alert System**
- Email notifications for heavily delayed routes
- Configurable delay thresholds
- Alert summary logging

✅ **Automation**
- Cron job scheduling
- Automatic report generation
- Log rotation and maintenance

✅ **Monitoring**
- Real-time delay tracking
- Historical data analysis
- Performance metrics

---

## 🎬 Demo

### Quick Start
```bash
# Run the complete pipeline
bash scripts/main.sh

# Run individual components
bash scripts/main.sh ingest      # Data ingestion only
bash scripts/main.sh calculate   # Delay calculation only
bash scripts/main.sh report      # Report generation only
bash scripts/main.sh alert       # Alert checks only
```

### Sample Output
```
========================================
   🚍 TRANSPORT DELAY TRACKER 🚊
========================================
   Date: 2025-11-02
   Time: 14:20:14
========================================

✅ Data ingestion complete (15 records)
✅ Delay calculation complete (86.67% on-time)
✅ Reports generated (CSV + HTML + PDF)
✅ Alerts checked (2 major delays found)
✅ Maintenance complete

Statistics:
-----------
Total Vehicles: 15
On-Time Vehicles: 13
On-Time Percentage: 86.67%
Average Delay: 3.40 minutes
Maximum Delay: 19 minutes
```

---

## 🏗️ Architecture

### System Flow
```
┌─────────────────┐
│  Timetable CSV  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────┐
│  Live Delay API │─────▶│   Ingestion  │
└─────────────────┘      └──────┬───────┘
                                │
                                ▼
                         ┌─────────────┐
                         │ Calculation │
                         └──────┬──────┘
                                │
                    ┌───────────┼───────────┐
                    ▼           ▼           ▼
                ┌──────┐   ┌──────┐   ┌──────┐
                │ CSV  │   │ HTML │   │ PDF  │
                └──────┘   └──────┘   └──────┘
                    │           │           │
                    └───────────┼───────────┘
                                ▼
                         ┌─────────────┐
                         │   Alerts    │
                         └─────────────┘
```

### Components

- **Data Layer** - CSV parsing, API integration
- **Processing Layer** - Delay calculation, statistics
- **Reporting Layer** - Multi-format report generation
- **Alert Layer** - Email notifications, logging
- **Automation Layer** - Cron scheduling, maintenance

---

## 📥 Installation

### Prerequisites
```bash
# Required
- Bash 4.0+
- awk, sed
- jq (JSON processor)

# Optional
- wkhtmltopdf (PDF generation)
- mailx (email alerts)
```

### Quick Install
```bash
# 1. Clone/Download the project
cd ~
mkdir transport-delay-tracker
cd transport-delay-tracker

# 2. Install dependencies
sudo apt-get update
sudo apt-get install -y jq wkhtmltopdf mailutils

# 3. Set up project structure
bash scripts/setup.sh  # (if available)

# 4. Configure settings
nano config/config.sh  # Edit API keys, email addresses

# 5. Run initial test
bash scripts/main.sh
```

For detailed installation instructions, see [INSTALL.md](INSTALL.md)

---

## 🚀 Usage

### Basic Commands
```bash
# Run complete pipeline
bash scripts/main.sh

# Run specific components
bash scripts/main.sh ingest      # Data ingestion
bash scripts/main.sh calculate   # Delay calculation
bash scripts/main.sh report      # Generate reports
bash scripts/main.sh alert       # Check alerts

# Automation
bash scripts/main.sh cron        # Set up cron jobs
bash scripts/main.sh status      # Check cron status

# Maintenance
bash scripts/main.sh clean       # Clean old files
bash scripts/main.sh help        # Show help
```

### Configuration

Edit `config/config.sh` to customize:
```bash
# Delay thresholds
MINOR_DELAY=5
MAJOR_DELAY=15
CRITICAL_DELAY=30

# Email settings
ALERT_EMAIL="your-email@example.com"

# API configuration
API_ENDPOINT="https://api.transit.com/delays"
API_KEY="your_api_key"
```

### Viewing Reports
```bash
# HTML Report (interactive)
xdg-open reports/daily/report_$(date +%Y-%m-%d).html

# PDF Report
xdg-open reports/daily/report_$(date +%Y-%m-%d).pdf

# CSV Report (for Excel)
libreoffice reports/daily/report_$(date +%Y-%m-%d).csv
```

For detailed usage guide, see [USER_GUIDE.md](USER_GUIDE.md)

---

## 📁 Project Structure
```
transport-delay-tracker/
├── scripts/
│   ├── main.sh                 # Main orchestrator
│   ├── ingest_data.sh          # Data ingestion
│   ├── calculate_delays.sh     # Delay calculation
│   ├── generate_reports.sh     # Report generation
│   ├── generate_pdf.sh         # PDF generation
│   ├── send_alerts.sh          # Alert system
│   ├── setup_cron.sh           # Cron automation
│   └── check_cron.sh           # Cron status
├── utils/
│   └── helpers.sh              # Utility functions
├── config/
│   └── config.sh               # Configuration
├── data/
│   ├── timetables/             # Schedule CSV files
│   ├── live_feeds/             # Live API data
│   └── processed/              # Processed data
├── reports/
│   ├── daily/                  # Daily reports
│   └── archive/                # Archived reports
├── logs/
│   ├── delays.log              # Application logs
│   └── cron/                   # Cron execution logs
├── README.md                   # This file
├── INSTALL.md                  # Installation guide
├── USER_GUIDE.md               # User manual
└── ARCHITECTURE.md             # Technical documentation
```

---

## 🛠️ Technologies

### Core Technologies

- **Bash** (5.0+) - Main scripting language
- **AWK** - Text processing and calculations
- **sed** - Stream editing
- **jq** - JSON parsing
- **cron** - Task scheduling

### Report Generation

- **Chart.js** - Interactive charts in HTML
- **wkhtmltopdf** - PDF generation
- **HTML5/CSS3** - Report styling

### Data Processing

- **CSV parsing** - Timetable data
- **JSON processing** - Live API data
- **curl** - API requests

---

## 📊 Screenshots

### HTML Report Dashboard
![Dashboard](docs/images/dashboard.png)

### Delay Analysis Charts
![Charts](docs/images/charts.png)

### PDF Report
![PDF Report](docs/images/pdf-report.png)

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Contact

**Project Maintainer:** [Hema Siri Guduru]

- Email: hemasiriguduru@gmail.com
- GitHub: [hemasiri-15](https://github.com/hemasiri-15)
- LinkedIn: [Hema Siri Guduru](https://linkedin.com/in/hema-siri-guduru-15sh)

**Project Link:** [https://github.com/hemasiri-15/transport-delay-tracker](https://github.com/hemasiri-15/transport-delay-tracker)

---

## 🙏 Acknowledgments

- Chart.js for visualization library
- wkhtmltopdf for PDF generation
- Public transport APIs for data
- Open source community

---

## 📈 Project Statistics

- **Lines of Code:** ~2000+
- **Scripts:** 8 main scripts
- **Report Formats:** 3 (CSV, HTML, PDF)
- **Data Points Tracked:** 15+ per execution
- **Automation:** Full cron integration

---

**Made with ❤️ for public transport monitoring**

---

*Last Updated: November 2025*
