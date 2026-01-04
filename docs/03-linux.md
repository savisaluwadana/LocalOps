# Linux In-Depth Theory

## Operating System Architecture

### The Kernel

The **kernel** is the core of Linux, responsible for managing all system resources.

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER SPACE                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ Applications│  │   Shells    │  │      System Services    │  │
│  │ (nginx,java)│  │ (bash,zsh)  │  │    (systemd, cron)      │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                    SYSTEM CALL INTERFACE                         │
├─────────────────────────────────────────────────────────────────┤
│                        KERNEL SPACE                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Process   │  │   Memory    │  │      File System        │  │
│  │ Management  │  │ Management  │  │      (ext4, xfs)        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │  Network    │  │   Device    │  │      Security           │  │
│  │   Stack     │  │  Drivers    │  │      (SELinux)          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                         HARDWARE                                 │
│    CPU    │    RAM    │    Disk    │    Network    │   GPU      │
└─────────────────────────────────────────────────────────────────┘
```

### Process Management

Every program in Linux runs as a **process**. The kernel manages:
- **Process creation** (fork, exec)
- **Scheduling** (which process runs when)
- **Inter-process communication** (pipes, signals, shared memory)
- **Process termination**

**Process States:**
```
┌──────────────┐
│   Created    │
└──────┬───────┘
       │
       ▼
┌──────────────┐     wait for I/O    ┌──────────────┐
│   Running    │◄───────────────────►│   Waiting    │
└──────┬───────┘                     └──────────────┘
       │
       ▼
┌──────────────┐     wait for parent ┌──────────────┐
│  Terminated  │◄───────────────────►│   Zombie     │
└──────────────┘                     └──────────────┘
```

**Example: Process hierarchy**
```bash
# View process tree
pstree -p

# Output shows parent-child relationships:
# systemd(1)─┬─sshd(1234)───sshd(5678)───bash(9012)───vim(3456)
#            ├─nginx(2345)─┬─nginx(2346)
#            │             └─nginx(2347)
#            └─docker(7890)
```

### Memory Management

Linux uses **virtual memory** to give each process the illusion of having its own address space.

**Key concepts:**
- **Pages**: 4KB chunks of memory
- **Page Table**: Maps virtual to physical addresses
- **Swap**: Disk space used when RAM is full
- **OOM Killer**: Terminates processes when memory is exhausted

```bash
# View memory usage
free -h
#               total        used        free      shared  buff/cache   available
# Mem:           16Gi       4.2Gi       8.1Gi       312Mi       3.7Gi        11Gi
# Swap:         4.0Gi          0B       4.0Gi

# Check what's using memory
ps aux --sort=-%mem | head -10

# View /proc for detailed info
cat /proc/meminfo
```

---

## File System Deep Dive

### Inodes and File Storage

Every file in Linux has an **inode** containing metadata:
- File size
- Owner/group
- Permissions
- Timestamps (created, modified, accessed)
- Pointers to data blocks

```bash
# View inode information
ls -i file.txt
stat file.txt

# Output:
#   File: file.txt
#   Size: 1234       Blocks: 8          IO Block: 4096   regular file
# Device: 803h/2051d Inode: 789456      Links: 1
# Access: (0644/-rw-r--r--)  Uid: ( 1000/   user)   Gid: ( 1000/   user)
# Access: 2024-01-15 10:30:00.000000000 +0000
# Modify: 2024-01-15 09:15:00.000000000 +0000
# Change: 2024-01-15 09:15:00.000000000 +0000
```

### Hard Links vs Symbolic Links

**Hard Link**: Another name pointing to the same inode
```bash
ln original.txt hardlink.txt
ls -li  # Same inode number
```

**Symbolic Link**: A file that points to another file's path
```bash
ln -s /path/to/original.txt symlink.txt
ls -l  # Shows symlink -> original.txt
```

**Diagram:**
```
Hard Links:                    Symbolic Links:
┌─────────────┐               ┌─────────────┐
│ file.txt    │───┐   ┌───────│ actual.txt  │
└─────────────┘   │   │       └─────────────┘
                  ▼   │              ▲
              ┌───────┴───┐         │
              │  Inode    │   ┌─────┴─────────┐
              │  (data)   │   │ link.txt      │
              └───────────┘   │ -> actual.txt │
┌─────────────┐   ▲           └───────────────┘
│ hardlink.txt│───┘
└─────────────┘
```

### File Descriptors

Every open file is represented by a **file descriptor** (integer).

| FD | Meaning |
|----|---------|
| 0 | stdin (standard input) |
| 1 | stdout (standard output) |
| 2 | stderr (standard error) |

**Redirection examples:**
```bash
# Redirect stdout to file
command > output.txt

# Redirect stderr to file
command 2> errors.txt

# Redirect both to same file
command > all.txt 2>&1

# Redirect both (modern syntax)
command &> all.txt

# Append instead of overwrite
command >> output.txt

# Pipe stdout to another command
command1 | command2

# Discard output
command > /dev/null 2>&1
```

---

## Networking Deep Dive

### TCP/IP Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                    APPLICATION LAYER                             │
│           HTTP, HTTPS, SSH, DNS, SMTP, FTP                       │
├─────────────────────────────────────────────────────────────────┤
│                    TRANSPORT LAYER                               │
│                   TCP (reliable), UDP (fast)                     │
├─────────────────────────────────────────────────────────────────┤
│                    NETWORK LAYER                                 │
│                   IP addressing, routing                         │
├─────────────────────────────────────────────────────────────────┤
│                    DATA LINK LAYER                               │
│                   Ethernet, MAC addresses                        │
├─────────────────────────────────────────────────────────────────┤
│                    PHYSICAL LAYER                                │
│              Cables, signals, wireless                           │
└─────────────────────────────────────────────────────────────────┘
```

### IP Addressing

**IPv4:** 32-bit (e.g., 192.168.1.100)
**IPv6:** 128-bit (e.g., 2001:0db8:85a3::8a2e:0370:7334)

**CIDR Notation:**
```
192.168.1.0/24 = 256 addresses (192.168.1.0 - 192.168.1.255)
10.0.0.0/8 = 16,777,216 addresses
172.16.0.0/16 = 65,536 addresses
```

**Private IP Ranges:**
| Range | Usage |
|-------|-------|
| 10.0.0.0/8 | Large organizations |
| 172.16.0.0/12 | Medium organizations |
| 192.168.0.0/16 | Home/small networks |

### Network Commands in Practice

```bash
# View all network interfaces
ip addr show

# Add an IP address
sudo ip addr add 192.168.1.50/24 dev eth0

# View routing table
ip route show
# default via 192.168.1.1 dev eth0
# 192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.100

# Add a route
sudo ip route add 10.0.0.0/8 via 192.168.1.1

# DNS lookup
dig google.com
nslookup google.com

# Trace route
traceroute google.com

# Check what's listening
ss -tuln
netstat -tuln

# Network connections
ss -tp  # TCP connections with process info
```

### iptables Firewall

**Chain flow:**
```
Incoming Packet → PREROUTING → INPUT → Application
                      ↓
                  FORWARD → POSTROUTING → Outgoing
                      ↑
Application → OUTPUT ─┘
```

**Examples:**
```bash
# List rules
sudo iptables -L -n -v

# Allow SSH
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow established connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Drop all other incoming
sudo iptables -A INPUT -j DROP

# NAT (for containers/VMs)
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

---

## Advanced Bash Scripting

### Arrays

```bash
# Indexed array
fruits=("apple" "banana" "cherry")
echo ${fruits[0]}       # apple
echo ${fruits[@]}       # all elements
echo ${#fruits[@]}      # length (3)

# Associative array (dictionary)
declare -A users
users[john]="admin"
users[jane]="developer"
echo ${users[john]}     # admin
echo ${!users[@]}       # all keys
```

### Functions

```bash
#!/bin/bash

# Function with return value
get_status() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        return 0  # Success
    else
        return 1  # Failure
    fi
}

# Function with output
deploy_app() {
    local app_name=$1
    local version=$2
    
    echo "Deploying $app_name version $version..."
    # Deployment logic here
    echo "$app_name deployed successfully"
}

# Usage
if get_status nginx; then
    echo "nginx is running"
else
    echo "nginx is NOT running"
fi

result=$(deploy_app "myapp" "v1.2.3")
echo "$result"
```

### Error Handling

```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined var, pipe failure

# Trap errors
trap 'echo "Error on line $LINENO"' ERR

# Trap cleanup on exit
cleanup() {
    echo "Cleaning up..."
    rm -f /tmp/tempfile
}
trap cleanup EXIT

# Try-catch pattern
{
    risky_command
} || {
    echo "risky_command failed, handling error..."
    exit 1
}

# Check command success
if ! cp source dest; then
    echo "Copy failed"
    exit 1
fi
```

### Practical Script: Deployment

```bash
#!/bin/bash
set -euo pipefail

# Configuration
APP_NAME="${APP_NAME:-myapp}"
DEPLOY_DIR="/var/www/${APP_NAME}"
BACKUP_DIR="/var/backups/${APP_NAME}"
LOG_FILE="/var/log/${APP_NAME}-deploy.log"

# Logging function
log() {
    local level=$1
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

# Check prerequisites
check_prereqs() {
    log INFO "Checking prerequisites..."
    
    for cmd in docker rsync; do
        if ! command -v $cmd &> /dev/null; then
            log ERROR "Required command not found: $cmd"
            exit 1
        fi
    done
    
    log INFO "Prerequisites OK"
}

# Backup current version
backup() {
    log INFO "Creating backup..."
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/${timestamp}"
    
    mkdir -p "$backup_path"
    if [[ -d "$DEPLOY_DIR" ]]; then
        rsync -av "$DEPLOY_DIR/" "$backup_path/"
        log INFO "Backup created at $backup_path"
    else
        log WARN "Nothing to backup"
    fi
}

# Deploy new version
deploy() {
    local version=$1
    log INFO "Deploying version $version..."
    
    # Pull container
    docker pull "${APP_NAME}:${version}"
    
    # Stop old container
    docker stop "$APP_NAME" 2>/dev/null || true
    docker rm "$APP_NAME" 2>/dev/null || true
    
    # Start new container
    docker run -d \
        --name "$APP_NAME" \
        --restart unless-stopped \
        -p 8080:8080 \
        "${APP_NAME}:${version}"
    
    log INFO "Container started"
}

# Health check
health_check() {
    log INFO "Running health check..."
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -sf http://localhost:8080/health > /dev/null; then
            log INFO "Health check passed"
            return 0
        fi
        log WARN "Health check attempt $attempt/$max_attempts failed"
        ((attempt++))
        sleep 2
    done
    
    log ERROR "Health check failed after $max_attempts attempts"
    return 1
}

# Main
main() {
    local version=${1:-latest}
    
    log INFO "Starting deployment of $APP_NAME:$version"
    
    check_prereqs
    backup
    deploy "$version"
    
    if health_check; then
        log INFO "Deployment completed successfully"
    else
        log ERROR "Deployment failed, consider rolling back"
        exit 1
    fi
}

main "$@"
```
