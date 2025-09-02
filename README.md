# Industry-Grade Bug Bounty Reconnaissance Pipeline

![CI Status](https://github.com/username/bug-bounty-recon/workflows/CI/badge.svg)
![Docker](https://img.shields.io/docker/automated/username/bug-bounty-recon)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

An automated, scalable, and industry-grade reconnaissance pipeline for bug bounty hunting and security assessments. Built with Docker for consistent deployment across environments.

## 🚀 Features

- **Comprehensive Subdomain Enumeration**: Amass passive/active discovery
- **High-Speed Port Scanning**: Masscan + Nmap service detection  
- **HTTP Service Discovery**: Httpx with technology detection
- **Vulnerability Assessment**: Nuclei with latest CVE templates
- **Multi-Format Reporting**: CSV, Markdown, and JSON outputs
- **Robust Error Handling**: Retry mechanisms and comprehensive logging
- **Configurable Parameters**: Environment-based configuration
- **CI/CD Ready**: GitHub Actions integration with automated testing

## 📋 Prerequisites

- Docker Engine 20.10+
- 4GB+ RAM recommended
- Network access for reconnaissance tools

## 🔧 Quick Start

### 1. Clone and Build
```bash
git clone https://github.com/username/bug-bounty-recon.git
cd bug-bounty-recon
docker build -t recon-pipeline .
```

### 2. Basic Usage
```bash
# Run reconnaissance on target domain
docker run --rm -v $(pwd)/results:/recon recon-pipeline ./recon.sh example.com

# Results will be available in ./results/example.com/
```

### 3. Advanced Configuration
```bash
# Custom configuration with environment variables
docker run --rm \
  -e MASSCAN_RATE=2000 \
  -e PORTS=1-10000 \
  -e HTTPX_THREADS=100 \
  -v $(pwd)/results:/recon \
  recon-pipeline ./recon.sh target.com
```

## 📁 Project Structure

```
bug-bounty-recon/
├── Dockerfile                  # Container definition
├── recon.sh                   # Main pipeline orchestrator
├── config/
│   └── config.sh             # Configuration parameters
├── scripts/
│   ├── utils.sh              # Utility functions and logging
│   ├── enumerate.sh          # Subdomain enumeration module
│   ├── scan.sh               # Port/service scanning module
│   ├── http_probe.sh         # HTTP probing and vulnerability assessment
│   └── aggregate.sh          # Report generation and aggregation
├── .github/workflows/
│   └── ci.yml                # CI/CD pipeline configuration
├── test_script.sh            # Test suite for pipeline validation
└── README.md                 # This file
```

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MASSCAN_RATE` | 1000 | Packets per second for masscan |
| `PORTS` | 1-1000 | Port range to scan |
| `HTTPX_THREADS` | 75 | Concurrent threads for HTTP probing |
| `NUCLEI_THREADS` | 50 | Concurrent threads for vulnerability scanning |
| `MAX_RETRIES` | 3 | Maximum retry attempts for failed operations |
| `WEBHOOKS_URL` | "" | Slack/Discord webhook for notifications |

### Configuration File

Edit `config/config.sh` to modify default behavior:

```bash
# Tool Configuration
export MASSCAN_RATE="${MASSCAN_RATE:-1000}"
export PORTS="${PORTS:-1-1000}"
export HTTPX_THREADS="${HTTPX_THREADS:-75}"

# Timeout Configuration (seconds)
export DNS_TIMEOUT="${DNS_TIMEOUT:-10}"
export MASSCAN_TIMEOUT="${MASSCAN_TIMEOUT:-300}"
```

## 📊 Output Structure

After execution, results are organized as follows:

```
target.com/
├── raw/                      # Raw tool outputs
│   ├── all_subdomains.txt   # Discovered subdomains
│   ├── unique_ips.txt       # Resolved IP addresses
│   ├── masscan_results.gnmap # Port scan results
│   ├── nmap_all_results.xml # Service detection
│   ├── httpx_results.txt    # HTTP endpoints
│   └── nuclei_all_results.txt # Vulnerability findings
├── reports/                  # Generated reports
│   ├── recon_report.md      # Human-readable summary
│   ├── recon_summary.csv    # Metrics and statistics
│   ├── detailed_findings.csv # Comprehensive data export
│   └── recon_data.json      # Machine-readable results
└── logs/                     # Execution logs
    └── YYYYMMDD_HHMMSS_target.com.log
```

## 🧪 Testing

Run the test suite to validate installation:

```bash
# Inside container
./test_script.sh

# Or with Docker
docker run --rm recon-pipeline ./test_script.sh
```

## 🔒 Security Considerations

- **Scope Limitation**: Only scan domains you own or have explicit permission to test
- **Rate Limiting**: Adjust `MASSCAN_RATE` to avoid overwhelming target infrastructure  
- **Data Handling**: Results may contain sensitive information - handle accordingly
- **Legal Compliance**: Ensure reconnaissance activities comply with local laws and regulations

## 📈 Performance Tuning

### For Large Targets (1000+ subdomains):
```bash
docker run --rm \
  -e MASSCAN_RATE=2000 \
  -e HTTPX_THREADS=100 \
  -e NUCLEI_THREADS=75 \
  --cpus=4 --memory=8g \
  -v $(pwd)/results:/recon \
  recon-pipeline ./recon.sh large-target.com
```

### For Stealth Reconnaissance:
```bash
docker run --rm \
  -e MASSCAN_RATE=100 \
  -e HTTPX_THREADS=10 \
  -e DNS_TIMEOUT=30 \
  -v $(pwd)/results:/recon \
  recon-pipeline ./recon.sh target.com
```

## 🛠️ Development

### Adding New Modules

1. Create script in `scripts/` directory
2. Follow existing pattern: source config and utils
3. Implement error handling and logging
4. Add tests to `test_script.sh`
5. Update documentation

### Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This tool is for authorized security testing only. Users are responsible for complying with applicable laws and regulations. The authors are not liable for any misuse or damage caused by this software.

## 🙏 Acknowledgments

- [OWASP Amass](https://github.com/OWASP/Amass) - Subdomain enumeration
- [ProjectDiscovery](https://projectdiscovery.io/) - Nuclei, Httpx tools
- [Masscan](https://github.com/robertdavidgraham/masscan) - High-speed port scanner
- [Nmap](https://nmap.org/) - Network discovery and security auditing

---

**Built by:** Dhananjay Jha | **LinkedIn:** [linkedin.com/in/dhananjayjha](https://www.linkedin.com/in/dhananjay-jha-8008091b6/)