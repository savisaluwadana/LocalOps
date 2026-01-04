# Linux Fundamentals

## What is Linux?

Linux is an **open-source operating system kernel** created by Linus Torvalds in 1991. Unlike Windows or macOS, "Linux" technically refers only to the kernel—the core component that manages hardware, memory, and processes. What we commonly call "Linux" is actually a **Linux distribution** (distro), which bundles the kernel with system utilities, package managers, and desktop environments.

### Why Linux for DevOps?

| Reason | Explanation |
|--------|-------------|
| **Server Dominance** | 96%+ of the world's top servers run Linux |
| **Container Foundation** | Docker, Kubernetes, and most containers are Linux-based |
| **Scripting Power** | Bash scripting automates everything |
| **SSH Everywhere** | Remote server management is Linux-native |
| **Free & Open Source** | No licensing costs, full customization |

---

## Core Concepts

### 1. The Filesystem Hierarchy

Linux uses a **single unified filesystem** starting from `/` (root), unlike Windows which uses drive letters.

```
/
├── bin/        → Essential user binaries (ls, cp, mv)
├── boot/       → Boot loader files
├── dev/        → Device files (disks, terminals)
├── etc/        → System configuration files
├── home/       → User home directories (/home/ubuntu)
├── lib/        → Shared libraries
├── opt/        → Optional/third-party software
├── proc/       → Virtual filesystem for process info
├── root/       → Root user's home directory
├── tmp/        → Temporary files
├── usr/        → User programs and data
│   ├── bin/    → Non-essential user binaries
│   ├── lib/    → Libraries for /usr/bin
│   └── local/  → Locally installed software
└── var/        → Variable data (logs, databases)
    └── log/    → System logs
```

### 2. Users and Permissions

Linux is a **multi-user system**. Every file has:
- An **owner** (user)
- A **group**
- Permissions for **owner**, **group**, and **others**

```bash
# View permissions
ls -la

# Output: -rwxr-xr--
# Breakdown:
# - = file type (d for directory)
# rwx = owner can read, write, execute
# r-x = group can read and execute
# r-- = others can only read
```

**Numeric Permissions:**
- `r` = 4, `w` = 2, `x` = 1
- `chmod 755` = rwxr-xr-x (common for scripts)
- `chmod 644` = rw-r--r-- (common for files)

### 3. Processes and Services

A **process** is a running program. A **service** (daemon) is a background process.

```bash
# View running processes
ps aux

# View resource usage
top
htop  # Better version (may need installation)

# Manage services (systemd)
sudo systemctl status nginx
sudo systemctl start nginx
sudo systemctl enable nginx  # Start on boot
```

### 4. Package Management

Different distros use different package managers:

| Distro | Package Manager | Example |
|--------|-----------------|---------|
| Ubuntu/Debian | apt | `sudo apt install nginx` |
| RHEL/CentOS | yum/dnf | `sudo dnf install nginx` |
| Alpine | apk | `apk add nginx` |
| Arch | pacman | `sudo pacman -S nginx` |

---

## Essential Commands

### Navigation & Files

```bash
# Where am I?
pwd

# List files
ls -la                    # Long format, show hidden
ls -lah                   # Human-readable sizes

# Change directory
cd /var/log               # Absolute path
cd ..                     # Up one level
cd ~                      # Home directory
cd -                      # Previous directory

# Create/Remove
mkdir -p /path/to/dir     # Create nested directories
touch file.txt            # Create empty file
rm file.txt               # Delete file
rm -rf directory/         # Delete directory recursively (DANGEROUS)

# Copy/Move
cp source dest
cp -r source_dir dest_dir # Copy directory
mv old_name new_name      # Rename or move
```

### File Content

```bash
# View files
cat file.txt              # Print entire file
less file.txt             # Paginated view (q to quit)
head -n 20 file.txt       # First 20 lines
tail -n 20 file.txt       # Last 20 lines
tail -f /var/log/syslog   # Follow log in real-time

# Search
grep "error" file.txt             # Find lines with "error"
grep -r "pattern" /path/          # Recursive search
grep -i "pattern" file.txt        # Case insensitive

# Edit
nano file.txt             # Simple editor
vim file.txt              # Powerful editor (steep learning curve)
```

### Networking

```bash
# Check IP address
ip addr
hostname -I

# Test connectivity
ping google.com
curl -I https://example.com   # HTTP headers only
curl https://api.example.com  # Full response

# Check open ports
ss -tuln                  # What's listening
netstat -tuln             # Legacy alternative

# Download files
wget https://example.com/file.zip
curl -O https://example.com/file.zip
```

### System Information

```bash
# OS info
cat /etc/os-release
uname -a

# Disk usage
df -h                     # Filesystem usage
du -sh /path/             # Directory size

# Memory
free -h

# CPU
lscpu
cat /proc/cpuinfo
```

---

## Hands-On Lab

### Exercise 1: Basic Navigation (10 mins)

```bash
# 1. Create your project structure
mkdir -p ~/projects/myapp/{src,config,logs}

# 2. Navigate into it
cd ~/projects/myapp

# 3. Create some files
touch src/app.py config/settings.yaml
echo "Hello World" > logs/app.log

# 4. Verify structure
find . -type f

# 5. Check permissions
ls -la src/
```

### Exercise 2: User Management (15 mins)

```bash
# 1. Create a new user
sudo useradd -m -s /bin/bash devuser

# 2. Set password
sudo passwd devuser

# 3. Add to sudo group (Ubuntu/Debian)
sudo usermod -aG sudo devuser

# 4. Switch to new user
su - devuser

# 5. Verify groups
groups

# 6. Return to original user
exit
```

### Exercise 3: Service Management (15 mins)

```bash
# 1. Install nginx
sudo apt update && sudo apt install -y nginx

# 2. Check status
sudo systemctl status nginx

# 3. View the web page
curl localhost

# 4. Stop the service
sudo systemctl stop nginx

# 5. Verify it's stopped
curl localhost  # Should fail

# 6. Start again and enable on boot
sudo systemctl start nginx
sudo systemctl enable nginx
```

---

## Bash Scripting Basics

### Your First Script

```bash
#!/bin/bash
# my_script.sh - A simple backup script

# Variables
SOURCE="/home/ubuntu/projects"
BACKUP="/var/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup
tar -czf "$BACKUP/backup_$TIMESTAMP.tar.gz" "$SOURCE"

# Report
echo "Backup created: backup_$TIMESTAMP.tar.gz"
```

Make it executable and run:
```bash
chmod +x my_script.sh
./my_script.sh
```

### Control Structures

```bash
#!/bin/bash

# If statement
if [ -f "/path/to/file" ]; then
    echo "File exists"
else
    echo "File not found"
fi

# For loop
for server in web1 web2 web3; do
    echo "Deploying to $server..."
    # ssh $server "deploy command here"
done

# While loop
counter=0
while [ $counter -lt 5 ]; do
    echo "Count: $counter"
    ((counter++))
done
```

---

## Further Learning

1. **Practice**: Use [OverTheWire Bandit](https://overthewire.org/wargames/bandit/) for Linux challenges
2. **Book**: "The Linux Command Line" by William Shotts (free online)
3. **Certification**: Consider LFCS (Linux Foundation Certified System Admin)
