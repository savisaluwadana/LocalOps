# Docker Fundamentals

[Previous content remains unchanged until Docker Networking section]

## Docker Networking

Docker networking is a powerful subsystem that enables communication between containers, hosts, and external networks. Understanding Docker networking is crucial for building scalable, secure, and performant containerized applications.

### 1. Docker Network Architecture Overview

Docker uses a pluggable networking architecture based on the Container Network Model (CNM). The CNM provides network abstraction and consists of three main components:

- **Sandbox**: Contains network configuration for a container (namespace, routing tables, DNS settings)
- **Endpoint**: Virtual network interface connecting a sandbox to a network
- **Network**: A group of endpoints that can communicate with each other

```
┌─────────────────────────────────────────────────────────────┐
│                        Docker Host                          │
│                                                             │
│  ┌──────────────┐      ┌──────────────┐                   │
│  │  Container 1 │      │  Container 2 │                   │
│  │              │      │              │                   │
│  │  ┌────────┐  │      │  ┌────────┐  │                   │
│  │  │Sandbox │  │      │  │Sandbox │  │                   │
│  │  │  eth0  │  │      │  │  eth0  │  │                   │
│  │  └───┬────┘  │      │  └───┬────┘  │                   │
│  └──────┼───────┘      └──────┼───────┘                   │
│         │                     │                           │
│    ┌────▼─────────────────────▼────┐                      │
│    │      Docker Bridge (docker0)  │                      │
│    │       Network: 172.17.0.0/16  │                      │
│    └────────────┬──────────────────┘                      │
│                 │                                          │
│            ┌────▼────┐                                     │
│            │  eth0   │  Host Network Interface             │
│            └────┬────┘                                     │
└─────────────────┼──────────────────────────────────────────┘
                  │
                  ▼
            External Network
```

### 2. Bridge Networks - Deep Dive

Bridge networks are the default network driver in Docker. When you start Docker, a default bridge network is created automatically.

#### 2.1 Default Bridge Network

**Architecture**:
```
Host Machine (192.168.1.100)
│
├─── docker0 bridge (172.17.0.1)
│    │
│    ├─── veth-abc123 ←→ Container1 eth0 (172.17.0.2)
│    │
│    └─── veth-def456 ←→ Container2 eth0 (172.17.0.3)
│
└─── eth0 (Physical Interface)
```

**Packet Flow Diagram**:
```
Container A (172.17.0.2) → Container B (172.17.0.3)
│
├─ 1. Packet leaves Container A's eth0
│     Source: 172.17.0.2, Dest: 172.17.0.3
│
├─ 2. Enters veth pair (host side)
│
├─ 3. Reaches docker0 bridge
│     Bridge performs L2 switching
│
├─ 4. Forwarded to Container B's veth pair
│
└─ 5. Arrives at Container B's eth0
```

**Practical Example**:
```bash
# Create two containers on default bridge
docker run -d --name web1 nginx
docker run -d --name web2 nginx

# Inspect network details
docker network inspect bridge

# Get container IPs
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web1
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web2

# Test connectivity (Note: default bridge doesn't support DNS resolution by name)
docker exec web1 ping -c 3 $(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web2)
```

#### 2.2 Custom Bridge Networks (Recommended)

Custom bridge networks provide better isolation and automatic DNS resolution.

```bash
# Create custom bridge network
docker network create --driver bridge my-bridge-network

# Create with specific subnet and gateway
docker network create \
  --driver bridge \
  --subnet=192.168.100.0/24 \
  --gateway=192.168.100.1 \
  --ip-range=192.168.100.128/25 \
  custom-net

# Run containers on custom network
docker run -d --name app1 --network my-bridge-network nginx
docker run -d --name app2 --network my-bridge-network nginx

# Test DNS resolution (works on custom networks!)
docker exec app1 ping -c 3 app2
docker exec app2 curl http://app1
```

**Custom Bridge Network Architecture**:
```
┌─────────────────────────────────────────────────────┐
│ Custom Bridge Network (my-bridge-network)           │
│ Subnet: 192.168.100.0/24                           │
│                                                     │
│  ┌──────────────────┐      ┌──────────────────┐   │
│  │  app1            │      │  app2            │   │
│  │  192.168.100.2   │◄────►│  192.168.100.3   │   │
│  │                  │ DNS  │                  │   │
│  └──────────────────┘      └──────────────────┘   │
│                                                     │
│  Embedded DNS Server: 127.0.0.11                   │
│  DNS Resolution: app1 → 192.168.100.2              │
└─────────────────────────────────────────────────────┘
```

### 3. Container-to-Container Communication

#### 3.1 Same Network Communication

```bash
# Create a custom network
docker network create app-network

# Run database container
docker run -d \
  --name postgres-db \
  --network app-network \
  -e POSTGRES_PASSWORD=secret \
  postgres:14

# Run application container
docker run -d \
  --name web-app \
  --network app-network \
  -e DATABASE_URL=postgresql://postgres:secret@postgres-db:5432/mydb \
  myapp:latest

# The web-app can reach postgres-db using the container name as hostname
```

#### 3.2 Multi-Network Communication

Containers can be connected to multiple networks:

```bash
# Create frontend and backend networks
docker network create frontend
docker network create backend

# Run database on backend only
docker run -d --name db --network backend postgres:14

# Run API server on both networks
docker run -d --name api \
  --network backend \
  myapi:latest

docker network connect frontend api

# Run web server on frontend only
docker run -d --name web --network frontend nginx

# Result:
# - web can communicate with api (both on frontend)
# - api can communicate with db (both on backend)
# - web CANNOT communicate with db (network isolation)
```

**Multi-Network Architecture**:
```
┌──────────────────────────────────────────────────────┐
│                    Docker Host                       │
│                                                      │
│  ┌────────────────────┐  ┌────────────────────┐    │
│  │  Frontend Network  │  │  Backend Network   │    │
│  │                    │  │                    │    │
│  │  ┌─────┐           │  │           ┌─────┐ │    │
│  │  │ Web │           │  │           │ DB  │ │    │
│  │  └──┬──┘           │  │           └──┬──┘ │    │
│  │     │              │  │              │    │    │
│  │     │  ┌────────┐  │  │  ┌────────┐ │    │    │
│  │     └──┤  API   ├──┼──┼──┤  API   ├─┘    │    │
│  │        │(eth0)  │  │  │  │(eth1)  │      │    │
│  │        └────────┘  │  │  └────────┘      │    │
│  └────────────────────┘  └────────────────────┘    │
└──────────────────────────────────────────────────────┘
```

### 4. Port Mapping Deep Dive

Port mapping allows external access to containerized services using Docker's port forwarding mechanism.

#### 4.1 Port Mapping Mechanisms

When you publish a port, Docker creates iptables rules to forward traffic:

```bash
# Publish port 8080 on host to port 80 in container
docker run -d -p 8080:80 --name web nginx

# View the iptables rules Docker created
sudo iptables -t nat -L -n | grep 8080
```

**iptables Rules Created**:
```
Chain DOCKER (2 references)
target     prot opt source               destination
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 to:172.17.0.2:80

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination
MASQUERADE  tcp  --  172.17.0.2           172.17.0.2           tcp dpt:80
```

#### 4.2 Port Mapping Flow Diagram

```
External Client (192.168.1.50:54321)
│
├─ Request: 192.168.1.100:8080
│
▼
┌──────────────────────────────────────────┐
│ Host eth0 (192.168.1.100)                │
│                                          │
│ iptables PREROUTING                      │
│ DNAT: :8080 → 172.17.0.2:80             │
└──────────────────┬───────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│ docker0 bridge (172.17.0.1)              │
└──────────────────┬───────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│ Container (172.17.0.2:80)                │
│ nginx listening on port 80               │
└──────────────────────────────────────────┘

Response follows reverse path with SNAT
```

#### 4.3 Port Mapping Examples

```bash
# Map specific port
docker run -d -p 8080:80 nginx

# Map to specific interface
docker run -d -p 127.0.0.1:8080:80 nginx  # Only localhost

# Map random host port
docker run -d -p 80 nginx  # Docker assigns random port

# Map UDP ports
docker run -d -p 53:53/udp dns-server

# Map multiple ports
docker run -d -p 80:80 -p 443:443 nginx

# Map range of ports
docker run -d -p 8000-8010:8000-8010 myapp

# Publish all exposed ports to random ports
docker run -d -P nginx
```

### 5. Host Network Mode

In host mode, containers share the host's network namespace directly - no network isolation.

#### 5.1 Host Network Architecture

```
┌───────────────────────────────────────────┐
│           Docker Host                     │
│                                           │
│  ┌─────────────────────────────────┐     │
│  │  Container (host network)       │     │
│  │  No separate namespace          │     │
│  │  Direct access to host network  │     │
│  └─────────────────────────────────┘     │
│                  │                        │
│                  │ (shares)               │
│                  ▼                        │
│         ┌────────────────┐                │
│         │  Host Network  │                │
│         │  Namespace     │                │
│         │  eth0, lo, etc │                │
│         └────────────────┘                │
└───────────────────────────────────────────┘
```

#### 5.2 Host Network Examples

```bash
# Run container with host network
docker run -d --network host nginx

# No port mapping needed - container binds directly to host ports
# nginx listens on host's port 80 directly

# Performance test example
docker run -it --rm --network host nicolaka/netshoot iperf3 -s
```

#### 5.3 Performance Comparison

**Benchmark Results** (Typical):
```
Network Mode    | Throughput  | Latency  | Use Case
----------------|-------------|----------|------------------
Bridge          | ~10 Gbps    | ~0.1ms   | Default, isolated
Host            | ~40 Gbps    | ~0.01ms  | High-performance
Overlay         | ~8 Gbps     | ~0.2ms   | Multi-host
```

**When to Use Host Network**:
- High-performance networking requirements
- Need to bind to all host interfaces
- Running network monitoring tools
- Testing/development scenarios

**Limitations**:
- No network isolation
- Port conflicts with host services
- Doesn't work on Docker Desktop (Mac/Windows)
- Reduces container portability

### 6. None Network Mode

The `none` network provides complete network isolation - no network interfaces except loopback.

```bash
# Create container with no network
docker run -d --network none --name isolated alpine sleep 3600

# Verify no network interfaces (except lo)
docker exec isolated ip addr show
# Output shows only:
# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536
```

**Use Cases**:
- Maximum security isolation
- Batch processing jobs with no network needs
- Protecting sensitive data processing
- Testing applications in isolation

**Architecture**:
```
┌─────────────────────────┐
│  Container (none)       │
│                         │
│  ┌──────────────────┐   │
│  │  Network Stack   │   │
│  │  lo: 127.0.0.1   │   │
│  │  (loopback only) │   │
│  └──────────────────┘   │
│                         │
│  No external network    │
└─────────────────────────┘
```

### 7. Network Namespaces Explained

Network namespaces provide network isolation by giving each container its own network stack.

#### 7.1 Namespace Components

Each network namespace includes:
- Network devices (virtual interfaces)
- IP addresses and routing tables
- Firewall rules (iptables/nftables)
- Network statistics
- Port numbers

#### 7.2 Exploring Network Namespaces

```bash
# List all network namespaces
sudo ls -la /var/run/docker/netns/

# Run a container
docker run -d --name test nginx

# Find the container's network namespace
container_pid=$(docker inspect -f '{{.State.Pid}}' test)
echo $container_pid

# Enter the container's network namespace using nsenter
sudo nsenter -t $container_pid -n ip addr show

# Or use docker exec
docker exec test ip addr show

# View routing table inside container
docker exec test ip route show

# View iptables rules
docker exec test iptables -L -n
```

#### 7.3 Virtual Ethernet (veth) Pairs

```bash
# Create container
docker run -d --name web nginx

# Find veth pair on host
container_if=$(docker exec web cat /sys/class/net/eth0/iflink)
ip link | grep "^${container_if}:"

# This shows the host-side veth interface connected to the container
```

**veth Pair Visualization**:
```
┌─────────────────────────────────────────────────────────┐
│                     Docker Host                         │
│                                                         │
│  Container Namespace          Host Namespace           │
│  ┌──────────────────┐        ┌──────────────────┐     │
│  │  eth0@if8        │◄──────►│  veth1a2b3c4@if7 │     │
│  │  172.17.0.2      │        │  (no IP)         │     │
│  └──────────────────┘        └────────┬─────────┘     │
│                                        │               │
│                              ┌─────────▼─────────┐     │
│                              │   docker0 bridge  │     │
│                              │   172.17.0.1      │     │
│                              └───────────────────┘     │
└─────────────────────────────────────────────────────────┘
```

### 8. Overlay Networks for Swarm/Multi-Host

Overlay networks enable container communication across multiple Docker hosts.

#### 8.1 Overlay Network Architecture

```
┌─────────────────────┐          ┌─────────────────────┐
│   Docker Host 1     │          │   Docker Host 2     │
│   192.168.1.10      │          │   192.168.1.20      │
│                     │          │                     │
│  ┌──────────────┐   │          │   ┌──────────────┐ │
│  │ Container A  │   │          │   │ Container B  │ │
│  │ 10.0.0.2     │   │          │   │ 10.0.0.3     │ │
│  └──────┬───────┘   │          │   └──────┬───────┘ │
│         │           │          │          │         │
│    ┌────▼──────┐    │          │    ┌─────▼─────┐   │
│    │  Overlay  │    │          │    │  Overlay  │   │
│    │  Network  │    │          │    │  Network  │   │
│    │ 10.0.0.0/24│   │          │    │ 10.0.0.0/24│  │
│    └────┬───────┘   │          │    └─────┬──────┘  │
│         │ VXLAN     │          │          │ VXLAN   │
│    ┌────▼───────┐   │          │    ┌─────▼──────┐  │
│    │   eth0     ├───┼──────────┼────┤   eth0     │  │
│    └────────────┘   │   VXLAN  │    └────────────┘  │
│                     │  Tunnel  │                     │
└─────────────────────┘          └─────────────────────┘
```

#### 8.2 Creating Overlay Networks

```bash
# Initialize Swarm (required for overlay networks)
docker swarm init

# Create overlay network
docker network create \
  --driver overlay \
  --subnet 10.0.0.0/24 \
  --gateway 10.0.0.1 \
  my-overlay

# Create attachable overlay (for standalone containers)
docker network create \
  --driver overlay \
  --attachable \
  app-overlay

# Deploy service using overlay network
docker service create \
  --name web \
  --network my-overlay \
  --replicas 3 \
  nginx

# Containers across hosts can communicate via service name
```

#### 8.3 Overlay Network Features

**Encapsulation**:
- Uses VXLAN (Virtual Extensible LAN)
- UDP port 4789 for VXLAN traffic
- Encrypted option available

```bash
# Create encrypted overlay network
docker network create \
  --driver overlay \
  --opt encrypted \
  secure-overlay
```

**Packet Flow in Overlay**:
```
Container A (Host 1) → Container B (Host 2)

1. Packet created: src=10.0.0.2, dst=10.0.0.3
2. VXLAN encapsulation adds outer header
   Outer: src=192.168.1.10, dst=192.168.1.20
   Inner: src=10.0.0.2, dst=10.0.0.3
3. Packet sent over physical network
4. Host 2 receives, de-encapsulates VXLAN
5. Inner packet delivered to Container B
```

### 9. Macvlan Networks for Direct Network Access

Macvlan allows containers to appear as physical devices on the network with their own MAC addresses.

#### 9.1 Macvlan Architecture

```
┌─────────────────────────────────────────────────────┐
│              Physical Network (192.168.1.0/24)      │
│                                                     │
│  Router: 192.168.1.1                                │
│     │                                               │
│     ├── Host: 192.168.1.100                         │
│     ├── Container1: 192.168.1.101 (MAC: aa:bb:..)   │
│     └── Container2: 192.168.1.102 (MAC: cc:dd:..)   │
└─────────────────────────────────────────────────────┘

Docker Host (192.168.1.100)
│
├─── eth0 (Physical Interface)
│    │
│    ├─── eth0.10 (macvlan sub-interface)
│         │
│         ├─── Container1 (192.168.1.101)
│         └─── Container2 (192.168.1.102)
```

#### 9.2 Creating Macvlan Networks

```bash
# Create macvlan network
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  macvlan-net

# Run container with macvlan
docker run -d \
  --network macvlan-net \
  --ip=192.168.1.101 \
  --name container1 \
  nginx

# Container appears as a separate device on the network
# Can be accessed directly at 192.168.1.101
```

#### 9.3 Macvlan Modes

**Bridge Mode** (default):
```bash
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  -o macvlan_mode=bridge \
  macvlan-bridge
```

**802.1Q VLAN Trunk**:
```bash
# Create macvlan on VLAN 10
docker network create -d macvlan \
  --subnet=10.10.10.0/24 \
  --gateway=10.10.10.1 \
  -o parent=eth0.10 \
  macvlan-vlan10

# Create macvlan on VLAN 20
docker network create -d macvlan \
  --subnet=10.10.20.0/24 \
  --gateway=10.10.20.1 \
  -o parent=eth0.20 \
  macvlan-vlan20
```

**Use Cases**:
- Legacy applications requiring direct network access
- Network monitoring tools
- DHCP servers
- Applications needing specific MAC addresses

**Limitations**:
- Requires promiscuous mode on NIC
- May not work in cloud environments
- Host cannot communicate with containers by default

### 10. Network Troubleshooting Techniques

#### 10.1 Essential Troubleshooting Commands

```bash
# Inspect network details
docker network inspect bridge
docker network inspect <network-name>

# View container network settings
docker inspect <container-name> | jq '.[0].NetworkSettings'

# List all networks
docker network ls

# Check container connectivity
docker exec <container> ping -c 3 <target>
docker exec <container> curl -v <url>
docker exec <container> wget -O- <url>

# DNS resolution testing
docker exec <container> nslookup <hostname>
docker exec <container> dig <hostname>
docker exec <container> cat /etc/resolv.conf

# View network interfaces in container
docker exec <container> ip addr show
docker exec <container> ifconfig

# Check routing table
docker exec <container> ip route show
docker exec <container> route -n

# Port listening verification
docker exec <container> netstat -tlnp
docker exec <container> ss -tlnp

# Test port connectivity
docker exec <container> telnet <host> <port>
docker exec <container> nc -zv <host> <port>
```

#### 10.2 Advanced Debugging with netshoot

```bash
# Run netshoot container with network debugging tools
docker run -it --rm --network container:<target-container> nicolaka/netshoot

# Inside netshoot, you have access to:
# - tcpdump, wireshark (tshark)
# - nmap, ncat, socat
# - curl, wget, httpie
# - dig, nslookup, drill
# - iperf3, ab (apache bench)
# - and many more...

# Capture packets
tcpdump -i eth0 -w /tmp/capture.pcap

# Scan ports
nmap -sT localhost

# HTTP performance testing
ab -n 1000 -c 10 http://web/

# Network performance
iperf3 -c <server-ip>
```

#### 10.3 Analyzing iptables Rules

```bash
# View all iptables rules Docker created
sudo iptables -t nat -L -n -v
sudo iptables -t filter -L -n -v

# View Docker-specific chains
sudo iptables -t nat -L DOCKER -n -v
sudo iptables -t filter -L DOCKER -n -v

# Trace packet flow
sudo iptables -t raw -A PREROUTING -p tcp --dport 8080 -j TRACE
sudo iptables -t raw -A OUTPUT -p tcp --sport 8080 -j TRACE

# View trace in logs
sudo tail -f /var/log/kern.log | grep TRACE
```

#### 10.4 Common Issues and Solutions

**Issue 1: Container Cannot Resolve DNS**
```bash
# Check DNS configuration
docker exec <container> cat /etc/resolv.conf

# Solution: Specify DNS servers
docker run --dns 8.8.8.8 --dns 8.8.4.4 <image>

# Or configure daemon-wide
# /etc/docker/daemon.json
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
```

**Issue 2: Containers on Default Bridge Cannot Communicate by Name**
```bash
# Problem: Default bridge doesn't support automatic DNS
# Solution: Use custom bridge network
docker network create my-network
docker run --network my-network --name app1 <image>
docker run --network my-network --name app2 <image>
# Now app1 and app2 can resolve each other by name
```

**Issue 3: Port Already in Use**
```bash
# Check what's using the port
sudo lsof -i :<port>
sudo netstat -tlnp | grep <port>

# Solution: Use different host port or stop conflicting service
docker run -p 8081:80 nginx  # Instead of 8080:80
```

**Issue 4: Cannot Access Published Ports**
```bash
# Check if port is actually published
docker port <container>

# Check if firewall is blocking
sudo iptables -L -n | grep <port>
sudo ufw status

# Check if binding to correct interface
docker run -p 0.0.0.0:8080:80 nginx  # All interfaces
docker run -p 127.0.0.1:8080:80 nginx  # Localhost only
```

### 11. Real-World Multi-Tier Application Network Architecture

Let's design a complete production-grade application network architecture.

#### 11.1 Application Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Docker Host                          │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │              Public Network (frontend)             │    │
│  │                                                     │    │
│  │  ┌──────────────┐         ┌──────────────┐        │    │
│  │  │   Nginx      │         │   Nginx      │        │    │
│  │  │   Proxy      │         │   Proxy      │        │    │
│  │  │   (LB)       │         │   (backup)   │        │    │
│  │  └──────┬───────┘         └──────────────┘        │    │
│  │         │                                          │    │
│  └─────────┼──────────────────────────────────────────┘    │
│            │                                               │
│  ┌─────────▼──────────────────────────────────────────┐    │
│  │           Application Network (backend)            │    │
│  │                                                     │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐        │    │
│  │  │  API     │  │  API     │  │  API     │        │    │
│  │  │  App 1   │  │  App 2   │  │  App 3   │        │    │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘        │    │
│  │       │             │             │               │    │
│  └───────┼─────────────┼─────────────┼───────────────┘    │
│          │             │             │                    │
│  ┌───────▼─────────────▼─────────────▼───────────────┐    │
│  │            Database Network (private)             │    │
│  │                                                    │    │
│  │  ┌──────────┐         ┌──────────┐               │    │
│  │  │ PostgreSQL│         │  Redis  │               │    │
│  │  │  Primary │         │  Cache  │               │    │
│  │  └──────────┘         └──────────┘               │    │
│  └────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌────────────────────────────────────────────────────┐    │
│  │         Monitoring Network (isolated)              │    │
│  │                                                     │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐        │    │
│  │  │Prometheus│  │ Grafana  │  │ Alertmgr │        │    │
│  │  └──────────┘  └──────────┘  └──────────┘        │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

#### 11.2 Implementation with Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

networks:
  frontend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
  
  backend:
    driver: bridge
    internal: false
    ipam:
      config:
        - subnet: 172.21.0.0/24
  
  database:
    driver: bridge
    internal: true  # No external access
    ipam:
      config:
        - subnet: 172.22.0.0/24
  
  monitoring:
    driver: bridge
    ipam:
      config:
        - subnet: 172.23.0.0/24

services:
  # Load Balancer / Reverse Proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    networks:
      - frontend
      - backend
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - api-1
      - api-2
      - api-3
    deploy:
      replicas: 2
      restart_policy:
        condition: on-failure

  # API Application Instances
  api-1:
    image: myapp/api:latest
    networks:
      - backend
      - database
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/appdb
      - REDIS_URL=redis://cache:6379
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

  api-2:
    image: myapp/api:latest
    networks:
      - backend
      - database
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/appdb
      - REDIS_URL=redis://cache:6379

  api-3:
    image: myapp/api:latest
    networks:
      - backend
      - database
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/appdb
      - REDIS_URL=redis://cache:6379

  # Database
  db:
    image: postgres:14
    networks:
      - database
      - monitoring
    environment:
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=appdb
    volumes:
      - db-data:/var/lib/postgresql/data
    deploy:
      placement:
        constraints:
          - node.role == manager

  # Cache
  cache:
    image: redis:7-alpine
    networks:
      - database
      - monitoring
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data

  # Monitoring Stack
  prometheus:
    image: prom/prometheus:latest
    networks:
      - monitoring
      - backend
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'

  grafana:
    image: grafana/grafana:latest
    networks:
      - monitoring
      - frontend
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  db-data:
  redis-data:
  prometheus-data:
  grafana-data:
```

#### 11.3 Manual Setup Commands

```bash
# Create networks
docker network create --subnet=172.20.0.0/24 frontend
docker network create --subnet=172.21.0.0/24 backend
docker network create --subnet=172.22.0.0/24 --internal database
docker network create --subnet=172.23.0.0/24 monitoring

# Database layer
docker run -d \
  --name postgres \
  --network database \
  -e POSTGRES_PASSWORD=secret \
  -v pgdata:/var/lib/postgresql/data \
  postgres:14

docker run -d \
  --name redis \
  --network database \
  redis:7-alpine

# Connect database to monitoring
docker network connect monitoring postgres
docker network connect monitoring redis

# Application layer
for i in 1 2 3; do
  docker run -d \
    --name api-$i \
    --network backend \
    -e DATABASE_URL=postgresql://postgres:secret@postgres:5432/db \
    -e REDIS_URL=redis://redis:6379 \
    myapi:latest
  
  docker network connect database api-$i
done

# Frontend layer
docker run -d \
  --name nginx \
  --network frontend \
  -p 80:80 -p 443:443 \
  -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro \
  nginx:alpine

docker network connect backend nginx

# Monitoring
docker run -d \
  --name prometheus \
  --network monitoring \
  -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
  prom/prometheus

docker network connect backend prometheus

docker run -d \
  --name grafana \
  --network monitoring \
  -p 3000:3000 \
  grafana/grafana

docker network connect frontend grafana
```

### 12. Security Considerations and Network Isolation

#### 12.1 Network Isolation Best Practices

**Principle of Least Privilege**:
```bash
# Create isolated networks for different tiers
docker network create --internal db-network
docker network create --internal cache-network
docker network create app-network

# Only expose what's necessary
# Database: Only on db-network
docker run -d --name db --network db-network postgres

# App: On both app and db networks
docker run -d --name api --network app-network myapi
docker network connect db-network api

# Proxy: Only on app network, published ports
docker run -d --name proxy --network app-network -p 80:80 nginx
```

#### 12.2 Internal Networks

Internal networks prevent external access completely:

```bash
# Create internal network (no gateway, no external access)
docker network create --internal secure-network

# Containers can communicate with each other but not external world
docker run -d --name db --network secure-network postgres
docker run -d --name app --network secure-network myapp

# App cannot reach internet, only db
```

#### 12.3 Network Policies and Firewall Rules

```bash
# Custom iptables rules for additional security
# Block inter-container communication except on specific ports

# Allow only port 5432 between app and db
sudo iptables -I DOCKER-USER -s 172.18.0.0/24 -d 172.19.0.2 -p tcp --dport 5432 -j ACCEPT
sudo iptables -I DOCKER-USER -s 172.18.0.0/24 -d 172.19.0.0/24 -j DROP

# Rate limiting
sudo iptables -I DOCKER-USER -p tcp --dport 80 -m state --state NEW -m recent --set
sudo iptables -I DOCKER-USER -p tcp --dport 80 -m state --state NEW -m recent --update --seconds 60 --hitcount 20 -j DROP
```

#### 12.4 Encrypted Networks

```bash
# Create encrypted overlay network (Swarm mode)
docker network create \
  --driver overlay \
  --opt encrypted \
  --attachable \
  secure-overlay

# All traffic between nodes is encrypted via IPSec
```

#### 12.5 Security Scanning and Monitoring

```bash
# Monitor network traffic
docker run -d \
  --name network-monitor \
  --network host \
  --cap-add NET_ADMIN \
  nicolaka/netshoot tcpdump -i any -w /captures/traffic.pcap

# Use Docker Bench Security
docker run -it --net host --pid host --userns host --cap-add audit_control \
  -v /etc:/etc:ro \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  docker/docker-bench-security

# Check for exposed services
nmap -sV -p- <docker-host-ip>
```

#### 12.6 Security Checklist

```
✓ Use custom bridge networks instead of default bridge
✓ Enable ICC (Inter-Container Communication) only when needed
✓ Use internal networks for databases and sensitive services
✓ Implement network segmentation (multi-tier architecture)
✓ Encrypt overlay networks in production
✓ Use TLS/SSL for all external communications
✓ Limit published ports to minimum required
✓ Bind ports to specific interfaces (127.0.0.1 for local only)
✓ Regularly audit network configurations
✓ Use secrets management for sensitive data
✓ Monitor network traffic for anomalies
✓ Keep Docker and kernels updated
✓ Use user namespaces when possible
✓ Implement rate limiting and DDoS protection
✓ Regular security scanning of images and containers
```

### 13. Performance Tuning for Networks

#### 13.1 Network Driver Selection

**Performance Characteristics**:
```
Driver      | Overhead | Isolation | Multi-Host | Use Case
------------|----------|-----------|------------|------------------
host        | Minimal  | None      | No         | Max performance
bridge      | Low      | Good      | No         | Default choice
macvlan     | Low      | Medium    | No         | Direct access
overlay     | Medium   | Good      | Yes        | Swarm/multi-host
```

#### 13.2 Kernel Parameters Tuning

```bash
# /etc/sysctl.conf optimizations for Docker networking

# Increase connection tracking
net.netfilter.nf_conntrack_max = 1000000
net.netfilter.nf_conntrack_tcp_timeout_established = 600

# TCP tuning
net.core.somaxconn = 32768
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 10240 65535

# Buffer sizes
net.core.rmem_default = 262144
net.core.rmem_max = 134217728
net.core.wmem_default = 262144
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 87380 134217728

# Optimize for high throughput
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr

# Apply changes
sudo sysctl -p
```

#### 13.3 Docker Daemon Configuration

```json
// /etc/docker/daemon.json
{
  "default-address-pools": [
    {
      "base": "172.80.0.0/16",
      "size": 24
    }
  ],
  "mtu": 1500,
  "live-restore": true,
  "userland-proxy": false,  // Use hairpin NAT instead (better performance)
  "iptables": true,
  "ip-forward": true,
  "ip-masq": true,
  "ipv6": false,
  "fixed-cidr-v6": "",
  "bridge": "docker0",
  "default-gateway": "",
  "dns": ["8.8.8.8", "8.8.4.4"],
  "dns-opts": [],
  "dns-search": [],
  "bip": "172.17.0.1/16"
}
```

#### 13.4 MTU Optimization

```bash
# Check current MTU
docker network inspect bridge | grep com.docker.network.driver.mtu

# Create network with custom MTU (jumbo frames for 10GbE)
docker network create \
  --opt com.docker.network.driver.mtu=9000 \
  high-perf-network

# For overlay networks in Swarm
docker network create \
  --driver overlay \
  --opt com.docker.network.driver.mtu=1450 \
  overlay-net
```

#### 13.5 Performance Benchmarking

```bash
# Network throughput test
# Server container
docker run -it --rm --network host nicolaka/netshoot iperf3 -s

# Client container
docker run -it --rm --network host nicolaka/netshoot iperf3 -c <server-ip> -t 30

# Latency test
docker run -it --rm --network host nicolaka/netshoot ping -c 100 <target>

# HTTP performance
docker run -it --rm --network host nicolaka/netshoot \
  ab -n 10000 -c 100 http://<target>/

# Compare bridge vs host performance
echo "Bridge network:"
docker run --rm --network bridge nicolaka/netshoot iperf3 -c <server> -t 10

echo "Host network:"
docker run --rm --network host nicolaka/netshoot iperf3 -c <server> -t 10
```

#### 13.6 Monitoring Network Performance

```bash
# Install cAdvisor for container metrics
docker run -d \
  --name=cadvisor \
  --network=monitoring \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --publish=8080:8080 \
  google/cadvisor:latest

# Network statistics per container
docker stats --format "table {{.Container}}\t{{.NetIO}}"

# Detailed network metrics
docker inspect <container> | jq '.[0].NetworkSettings.Networks'
```

### 14. Debugging Network Issues with Practical Commands

#### 14.1 Connectivity Troubleshooting Workflow

```bash
# Step 1: Verify container is running
docker ps | grep <container-name>
docker inspect <container-name> | jq '.[0].State'

# Step 2: Check network connectivity
docker exec <container> ip addr show
docker exec <container> ip route show

# Step 3: Test DNS resolution
docker exec <container> nslookup <hostname>
docker exec <container> cat /etc/resolv.conf

# Step 4: Test connectivity to specific service
docker exec <container> ping -c 3 <target>
docker exec <container> telnet <host> <port>
docker exec <container> curl -v http://<service>

# Step 5: Check listening ports
docker exec <container> netstat -tlnp
docker exec <container> ss -tlnp

# Step 6: Verify iptables rules
sudo iptables -t nat -L -n -v | grep <container-ip>

# Step 7: Check Docker network configuration
docker network inspect <network-name>
```

#### 14.2 Packet Capture and Analysis

```bash
# Capture traffic on docker0 bridge
sudo tcpdump -i docker0 -w /tmp/docker-traffic.pcap

# Capture traffic for specific container
container_pid=$(docker inspect -f '{{.State.Pid}}' <container>)
sudo nsenter -t $container_pid -n tcpdump -i eth0 -w /tmp/container-traffic.pcap

# Capture with filters
sudo tcpdump -i docker0 'port 80 or port 443' -w /tmp/http-traffic.pcap

# Analyze with tshark
tshark -r /tmp/docker-traffic.pcap -Y "http.request"

# Real-time analysis
docker run -it --rm --net container:<target> nicolaka/netshoot
# Inside netshoot:
tcpdump -i eth0 -n -A 'port 80'
```

#### 14.3 DNS Debugging

```bash
# Check DNS configuration
docker exec <container> cat /etc/resolv.conf

# Test DNS resolution
docker exec <container> nslookup google.com
docker exec <container> dig google.com
docker exec <container> host google.com

# Test Docker embedded DNS
docker exec <container> nslookup <container-name>
docker exec <container> dig <container-name> @127.0.0.11

# Override DNS for testing
docker run --dns 8.8.8.8 --dns-search example.com <image>

# Check if DNS is working from host
docker run --rm alpine nslookup google.com
```

#### 14.4 Port Mapping Debugging

```bash
# List port mappings
docker port <container>

# Check if port is listening inside container
docker exec <container> netstat -tlnp | grep <port>

# Check if host port is listening
sudo netstat -tlnp | grep <host-port>
sudo lsof -i :<host-port>

# Test port from outside
telnet <docker-host-ip> <port>
nc -zv <docker-host-ip> <port>
curl -v http://<docker-host-ip>:<port>

# Check iptables NAT rules
sudo iptables -t nat -L DOCKER -n -v
sudo iptables -t nat -L POSTROUTING -n -v

# Trace packets
sudo iptables -t raw -A PREROUTING -p tcp --dport <port> -j TRACE
sudo iptables -t raw -A OUTPUT -p tcp --sport <port> -j TRACE
```

#### 14.5 Inter-Container Communication Testing

```bash
# From container1 to container2
docker exec container1 ping -c 3 container2
docker exec container1 curl http://container2:port
docker exec container1 nc -zv container2 port

# Check if containers are on same network
docker inspect container1 | jq '.[0].NetworkSettings.Networks'
docker inspect container2 | jq '.[0].NetworkSettings.Networks'

# Test with netshoot
docker run -it --rm --network <network-name> nicolaka/netshoot
# From netshoot:
ping container1
nmap -p- container1
curl http://container2
```

#### 14.6 Advanced Debugging Scenarios

**Scenario 1: Container can't reach external services**
```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward  # Should be 1

# Enable if needed
sudo sysctl net.ipv4.ip_forward=1

# Check NAT rules
sudo iptables -t nat -L POSTROUTING -n -v

# Check if DNS is working
docker exec <container> ping 8.8.8.8  # Test IP
docker exec <container> ping google.com  # Test DNS

# Check routing
docker exec <container> ip route show
docker exec <container> traceroute google.com
```

**Scenario 2: Published port not accessible**
```bash
# Verify port is published
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Check firewall
sudo ufw status
sudo iptables -L -n | grep <port>

# Check if bound to correct interface
docker inspect <container> | jq '.[0].NetworkSettings.Ports'

# Test locally first
curl http://localhost:<port>

# Then test from host IP
curl http://$(hostname -I | awk '{print $1}'):<port>

# Check for port conflicts
sudo lsof -i :<port>
```

**Scenario 3: Slow network performance**
```bash
# Check for packet loss
docker exec <container> ping -c 100 <target> | grep loss

# MTU issues
docker exec <container> ping -M do -s 1472 <target>

# Check network stats
docker stats <container>

# Inspect for errors
ip -s link show docker0

# Test bandwidth
docker run --rm --network host nicolaka/netshoot iperf3 -c <server>
```

**Scenario 4: Overlay network issues**
```bash
# Check Swarm status
docker node ls
docker network ls --filter driver=overlay

# Verify encryption
docker network inspect <overlay-network> | jq '.[0].Options'

# Check VXLAN connectivity (port 4789)
sudo tcpdump -i <interface> udp port 4789

# Test cross-node connectivity
docker service create --name test --network <overlay> --replicas 2 alpine sleep 3600
docker exec $(docker ps -q --filter label=com.docker.swarm.service.name=test -n 1) \
  ping <other-replica-ip>
```

#### 14.7 Useful Network Debugging One-Liners

```bash
# Show all container IPs
docker inspect -f '{{.Name}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)

# Show all containers on a specific network
docker network inspect -f '{{range .Containers}}{{.Name}} {{.IPv4Address}} {{end}}' <network-name>

# Find which network a container is on
docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{$key}} {{end}}' <container>

# Get container's MAC address
docker inspect -f '{{range .NetworkSettings.Networks}}{{.MacAddress}}{{end}}' <container>

# Show all port mappings
docker ps --format "table {{.Names}}\t{{.Ports}}" | column -t

# Get gateway for a container
docker inspect -f '{{range .NetworkSettings.Networks}}{{.Gateway}}{{end}}' <container>

# Check if userland-proxy is running
ps aux | grep docker-proxy

# Monitor connection tracking
watch -n1 'sudo conntrack -L | wc -l'

# Show Docker network drivers
docker network ls --format "{{.Driver}}" | sort | uniq -c
```

---

## Docker Networking Best Practices Summary

1. **Use custom bridge networks** for automatic DNS resolution
2. **Implement network segmentation** for security (frontend/backend/database)
3. **Use internal networks** for databases and sensitive services
4. **Enable encryption** for overlay networks in production
5. **Minimize published ports** - only expose what's necessary
6. **Use host network** only when performance is critical
7. **Monitor network metrics** with cAdvisor or Prometheus
8. **Regular security audits** of network configurations
9. **Document network architecture** for your applications
10. **Test connectivity** thoroughly before deploying to production

[Rest of the document content continues unchanged...]

## Next Section
[Continue with the next section of the original document...]