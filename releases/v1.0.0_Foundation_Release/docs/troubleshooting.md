# Troubleshooting

## Installation fails
```bash
# Check internet
ping google.com

# Check disk space
df -h

# Check logs
tail -f /var/log/syslog
```

## Services won't start
```bash
sudo systemctl status apache2
sudo systemctl restart mysql
```

## Docker issues
```bash
sudo systemctl restart docker
docker system prune -f
```