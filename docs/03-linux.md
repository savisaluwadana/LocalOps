# Linux for DevOps Complete Guide

## Table of Contents

1. [Linux Fundamentals](#linux-fundamentals)
2. [File System](#file-system)
3. [User Management](#user-management)
4. [Process Management](#process-management)
5. [Networking](#networking)
6. [Package Management](#package-management)
7. [Shell Scripting](#shell-scripting)
8. [System Administration](#system-administration)
9. [Performance Tuning](#performance-tuning)

---

## Linux Fundamentals

### Why Linux for DevOps?

| Reason | Description |
|--------|-------------|
| Server dominance | 90%+ of servers run Linux |
| Container runtime | Docker runs on Linux kernel |
| Open source | Free, customizable, transparent |
| Automation friendly | Scriptable, CLI-first |
| Cloud native | All cloud providers support it |

### Linux Distributions

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       LINUX DISTRIBUTION FAMILIES                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   DEBIAN-BASED                     RHEL-BASED                           │
│   ├── Debian                       ├── RHEL (Red Hat)                   │
│   ├── Ubuntu                       ├── CentOS / Rocky / Alma            │
│   └── Linux Mint                   └── Fedora                           │
│   Package: apt/dpkg                Package: yum/dnf/rpm                 │
│                                                                          │
│   ARCH-BASED                       OTHER                                 │
│   ├── Arch Linux                   ├── Alpine (containers)              │
│   └── Manjaro                      ├── openSUSE                         │
│   Package: pacman                  └── Gentoo                           │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## File System

### Directory Structure

```
/                   # Root
├── bin             # Essential binaries
├── boot            # Boot loader files
├── dev             # Device files
├── etc             # Configuration files
├── home            # User home directories
├── lib             # Shared libraries
├── opt             # Optional software
├── proc            # Process information (virtual)
├── root            # Root user's home
├── tmp             # Temporary files
├── usr             # User programs
│   ├── bin         # User binaries
│   ├── lib         # User libraries
│   └── local       # Locally installed software
└── var             # Variable data
    ├── log         # Log files
    └── www         # Web server files
```

### Essential Commands

```bash
# Navigation
pwd                     # Print working directory
cd /path/to/dir         # Change directory
ls -la                  # List all files with details

# File operations
cp source dest          # Copy
mv source dest          # Move/rename
rm file                 # Remove
rm -rf dir              # Remove directory recursively

# File content
cat file                # Display file
less file               # Paginated view
head -n 10 file         # First 10 lines
tail -n 10 file         # Last 10 lines
tail -f file            # Follow file (logs)

# Search
find /path -name "*.log"              # Find by name
find /path -type f -mtime -1          # Modified in last day
grep "pattern" file                   # Search in file
grep -r "pattern" /path               # Recursive search

# Permissions
chmod 755 file          # rwxr-xr-x
chmod u+x file          # Add execute for user
chown user:group file   # Change owner
```

### File Permissions

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       FILE PERMISSIONS                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   -rwxr-xr-x   1   root root   4096   Jan 1 12:00   file.txt           │
│   │└┬┘└┬┘└┬┘       │    │      │                    │                   │
│   │ │  │  │        │    │      │                    └── Filename        │
│   │ │  │  │        │    │      └── Size                                 │
│   │ │  │  │        │    └── Group                                       │
│   │ │  │  │        └── Owner                                            │
│   │ │  │  └── Others (r-x = 5)                                          │
│   │ │  └── Group (r-x = 5)                                              │
│   │ └── Owner (rwx = 7)                                                 │
│   └── File type (- = file, d = directory, l = link)                    │
│                                                                          │
│   Numeric: r=4, w=2, x=1                                                │
│   755 = rwxr-xr-x (owner full, others read+execute)                    │
│   644 = rw-r--r-- (owner read+write, others read only)                 │
│   600 = rw------- (owner only)                                          │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## User Management

### Commands

```bash
# Create user
useradd -m -s /bin/bash username
passwd username

# Delete user
userdel -r username

# Modify user
usermod -aG docker username   # Add to group
usermod -s /bin/zsh username  # Change shell

# Groups
groupadd groupname
groups username               # List user's groups

# Switch user
su - username
sudo -u username command

# Sudo access
visudo                        # Edit sudoers file
```

### Sudoers Configuration

```bash
# /etc/sudoers.d/myuser
myuser ALL=(ALL) NOPASSWD: ALL           # No password for all
myuser ALL=(ALL) NOPASSWD: /usr/bin/docker  # Specific command
%devops ALL=(ALL) NOPASSWD: ALL          # Group
```

---

## Process Management

### Commands

```bash
# View processes
ps aux                        # All processes
ps aux | grep nginx           # Filter
top                           # Real-time view
htop                          # Better top

# Process control
kill <pid>                    # Graceful stop (SIGTERM)
kill -9 <pid>                 # Force stop (SIGKILL)
killall nginx                 # Kill by name

# Background processes
command &                     # Run in background
jobs                          # List background jobs
fg %1                         # Bring to foreground
bg %1                         # Continue in background
nohup command &               # Persist after logout

# System services (systemd)
systemctl start nginx
systemctl stop nginx
systemctl restart nginx
systemctl status nginx
systemctl enable nginx        # Start on boot
journalctl -u nginx -f        # View logs
```

---

## Networking

### Commands

```bash
# Network info
ip addr                       # IP addresses
ip route                      # Routing table
ss -tlnp                      # Listening ports
netstat -tlnp                 # Alternative

# DNS
nslookup example.com
dig example.com
cat /etc/resolv.conf

# Connectivity
ping host
traceroute host
curl -v http://example.com
wget http://example.com/file

# Firewall (iptables/nftables)
iptables -L -n                # List rules
ufw status                    # UFW (Ubuntu)
firewall-cmd --list-all       # firewalld (RHEL)
```

### Network Configuration

```bash
# Static IP (netplan - Ubuntu)
# /etc/netplan/01-config.yaml
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

# Apply
netplan apply
```

---

## Package Management

### Debian/Ubuntu (apt)

```bash
# Update package list
apt update

# Upgrade packages
apt upgrade

# Install package
apt install nginx

# Remove package
apt remove nginx
apt purge nginx              # Remove with config

# Search
apt search nginx

# Info
apt show nginx
```

### RHEL/CentOS (dnf/yum)

```bash
# Update
dnf update

# Install
dnf install nginx

# Remove
dnf remove nginx

# Search
dnf search nginx

# List installed
dnf list installed
```

---

## Shell Scripting

### Basics

```bash
#!/bin/bash
# Script header

# Variables
NAME="World"
echo "Hello, $NAME"

# Arguments
echo "Script: $0"
echo "First arg: $1"
echo "All args: $@"
echo "Count: $#"

# Conditionals
if [ "$1" == "test" ]; then
    echo "Test mode"
elif [ -z "$1" ]; then
    echo "No argument"
else
    echo "Unknown: $1"
fi

# Loops
for i in 1 2 3; do
    echo "Number: $i"
done

for file in *.log; do
    echo "Processing: $file"
done

while read line; do
    echo "$line"
done < file.txt

# Functions
greet() {
    local name=$1
    echo "Hello, $name"
}
greet "World"

# Exit codes
command || exit 1            # Exit if fails
command && echo "Success"    # Run if succeeds
```

### Best Practices

```bash
#!/bin/bash
set -euo pipefail            # Strict mode

# -e: Exit on error
# -u: Error on undefined variables
# -o pipefail: Fail on pipe errors

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting script..."
```

---

## System Administration

### Monitoring

```bash
# System info
uname -a                     # Kernel info
hostnamectl                  # Hostname info
uptime                       # Uptime and load

# Resources
free -h                      # Memory
df -h                        # Disk space
du -sh /path                 # Directory size
lsblk                        # Block devices

# Logs
journalctl -f                # Follow system log
tail -f /var/log/syslog      # System log
dmesg                        # Kernel messages
```

### Scheduled Tasks

```bash
# Crontab
crontab -e                   # Edit user crontab
crontab -l                   # List crontab

# Format: minute hour day month weekday command
# Every day at 3am
0 3 * * * /path/to/script.sh

# Every 5 minutes
*/5 * * * * /path/to/script.sh

# Systemd timers (modern alternative)
# /etc/systemd/system/backup.timer
[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

---

## Performance Tuning

### Analysis Tools

```bash
# CPU
top
mpstat 1
vmstat 1

# Memory
free -h
vmstat 1
cat /proc/meminfo

# Disk
iostat -x 1
iotop

# Network
iftop
nethogs
ss -s
```

### Kernel Parameters

```bash
# View current
sysctl -a

# Set temporarily
sysctl -w net.core.somaxconn=65535

# Permanent (/etc/sysctl.d/99-tuning.conf)
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
vm.swappiness = 10
```

This guide covers essential Linux knowledge for DevOps engineers with practical examples and commands.
