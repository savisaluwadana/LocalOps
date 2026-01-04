# DevOps Networking Guide

## Table of Contents

1. [Networking Fundamentals](#networking-fundamentals)
2. [The OSI Model](#the-osi-model)
3. [TCP/IP and UDP](#tcpip-and-udp)
4. [DNS Deep Dive](#dns-deep-dive)
5. [HTTP, HTTPS, and TLS](#http-https-and-tls)
6. [Cloud Networking (VPCs)](#cloud-networking-vpcs)
7. [Load Balancing](#load-balancing)
8. [Troubleshooting Tools](#troubleshooting-tools)

---

## Networking Fundamentals

Understanding networking is crucial for debugging connectivity, performance, and security issues in distributed systems.

### Key Concepts

-   **Bandwidth**: Maximum rate of data transfer across a given path.
-   **Throughput**: Actual rate of data transfer.
-   **Latency**: Time for a packet to travel from source to destination.
-   **Jitter**: Variation in latency.

---

## The OSI Model

Seven abstract layers that describe computer system communications.

| Layer | Name | Unit | DevOps Relevance | Examples |
|-------|------|------|------------------|----------|
| 7 | **Application** | Data | HTTP headers, specialized protocols | HTTP, SMTP, SSH, FTP |
| 6 | **Presentation** | Data | Encryption, encoding | SSL/TLS, JPEG, ASCII |
| 5 | **Session** | Data | Connection state | Sockets, RPC |
| 4 | **Transport** | Segment | Ports, reliability, flow control | TCP, UDP |
| 3 | **Network** | Packet | IP addressing, routing | IP, ICMP, IPSec |
| 2 | **Data Link** | Frame | MAC addresses, switching | Ethernet, Wi-Fi |
| 1 | **Physical** | Bit | Cables, signals | Fiber, Cat6 |

> **DevOps Focus**: Mostly Layers 3 (IP), 4 (TCP/UDP), and 7 (HTTP).

---

## TCP/IP and UDP

### TCP (Transmission Control Protocol)
**Connection-oriented, reliable, ordered.**

**The Three-Way Handshake:**
1.  **SYN**: Client sends "Let's connect" (seq=x).
2.  **SYN-ACK**: Server says "Okay, I see you" (ack=x+1, seq=y).
3.  **ACK**: Client says "Great, let's go" (ack=y+1).

**Features:**
-   **Reliability**: Retransmits lost packets.
-   **Flow Control**: Adjusts speed so receiver isn't overwhelmed.
-   **Congestion Control**: Slows down when network is busy.

**Use Cases**: Web (HTTP), Email (SMTP), File Transfer (FTP), Databases.

### UDP (User Datagram Protocol)
**Connectionless, unreliable, unordered.**

**Features:**
-   **Fire and Forget**: No handshake, no acknowledgement.
-   **Low Overhead**: Smaller header size.
-   **Fast**: No retransmission delays.

**Use Cases**: Streaming (VoIP, Video), DNS requests, Gaming.

---

## DNS Deep Dive

**Domain Name System (DNS)** is the phonebook of the internet, translating `google.com` to `142.250.190.46`.

### Record Types

| Type | Description | Example |
|------|-------------|---------|
| **A** | Hostname to IPv4 | `google.com -> 1.2.3.4` |
| **AAAA** | Hostname to IPv6 | `google.com -> 2001:db8::1` |
| **CNAME** | Alias to another canonical name | `www.google.com -> google.com` |
| **MX** | Mail Exchange | `google.com -> mail.google.com` |
| **NS** | Name Server (Authoritative) | `google.com -> ns1.google.com` |
| **TXT** | Text (Verification, SPF) | `v=spf1 include:_spf.google.com ~all` |
| **SOA** | Start of Authority | Zone details (admin email, refresh rate) |

### The Lookup Process

1.  **Browser Cache**: Check local browser.
2.  **OS Cache**: Check `/etc/hosts` or OS resolver cache.
3.  **Recursive Resolver**: ISP or Public DNS (8.8.8.8) is queried.
4.  **Root Server (.)**: "I don't know, ask the `.com` TLD server."
5.  **TLD Server (.com)**: "I don't know, ask `google.com` Authoritative NS."
6.  **Authoritative Nameserver**: "Here is the IP: `1.2.3.4`."

---

## HTTP, HTTPS, and TLS

### HTTP (Layer 7)

**Methods:**
-   `GET`: Retrieve data (Safe, Idempotent).
-   `POST`: Submit data (Not Safe, Not Idempotent).
-   `PUT`: Update/Create resource (Idempotent).
-   `DELETE`: Remove resource (Idempotent).
-   `PATCH`: Partial update.

**Status Codes:**
-   `1xx`: Informational.
-   `2xx`: Success (200 OK, 201 Created).
-   `3xx`: Redirection (301 Permanent, 302 Found).
-   `4xx`: Client Error (400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found).
-   `5xx`: Server Error (500 Internal, 502 Bad Gateway, 503 Unavailable).

### HTTPS and TLS Handshake (Overview)

1.  **Client Hello**: "I support TLS 1.2/1.3, here are my cipher suites."
2.  **Server Hello**: "Let's use TLS 1.3. Here is my Certificate (Public Key)."
3.  **Verification**: Client checks if specific Certificate Authority (CA) signed the cert.
4.  **Key Exchange**: Client and Server generate a shared symmetric Session Key.
5.  **Secure Communication**: All further data is encrypted with the Session Key.

---

## Cloud Networking (VPCs)

### CIDR Notation (Classless Inter-Domain Routing)

Describes a range of IP addresses. Format: `IP/PrefixLength`.

-   `/32`: 1 IP (Specific Host)
-   `/24`: 256 IPs (255.255.255.0 subnet mask) - Standard subnet size.
-   `/16`: 65,536 IPs (255.255.0.0 subnet mask) - Standard VPC size.
-   `/0`: All IPs (0.0.0.0/0) - The entire internet.

**Calculation:**
`$ 2^{(32 - PrefixLength)} = Total IPs`

### VPC Components

1.  **Subnets**: Meaningful segments of the VPC (Public vs Private).
2.  **Route Tables**: Rules for traffic flow (`0.0.0.0/0 -> Internet Gateway`).
3.  **Internet Gateway (IGW)**: Doorway to the public internet.
4.  **NAT Gateway**: Allows private subnets to send outbound traffic without accepting inbound.
5.  **Security Groups**: Stateful firewall at the **Instance** level.
6.  **NACLs (Network ACLs)**: Stateless firewall at the **Subnet** level.

---

## Load Balancing

### Layer 4 vs Layer 7

| Feature | Layer 4 (Network/Transport) | Layer 7 (Application) |
|---------|----------------------------|-----------------------|
| **Data** | Packet Header (IP + Port) | Application Data (HTTP Headers, URL) |
| **Logic** | "Round Robin to these IPs" | "If URL=/api, route to Service A" |
| **Speed** | Faster (Less processing) | Slower (Deep packet inspection) |
| **Context**| Unaware of request content | Aware of Cookies, User-Agent, etc. |
| **Examples**| AWS NLB, K8s Service | AWS ALB, Nginx, K8s Ingress |

### Algorithms
-   **Round Robin**: Sequential (A, B, C, A, B...).
-   **Least Connections**: Send to server with fewest active connections.
-   **IP Hash**: Client IP ensures sticky session to same server.

---

## Troubleshooting Tools

| Tool | Purpose | Example |
|------|---------|---------|
| **ping** | Check connectivity (ICMP) | `ping Google.com` |
| **curl** | Test HTTP requests | `curl -v -I https://api.com` |
| **dig** | Query DNS records | `dig +short google.com` |
| **nslookup**| Query DNS (legacy) | `nslookup google.com` |
| **telnet** | Test TCP port connection | `telnet host 80` |
| **nc (netcat)**| "Swiss army knife" | `nc -vz host 80` |
| **traceroute**| Show path to destination | `traceroute google.com` |
| **tcpdump** | Capture packets | `tcpdump -i eth0 port 80` |
| **netstat** | Show network stats | `netstat -tulpn` |
| **ss** | Modern netstat replacement | `ss -tulpn` |

### Debugging Workflow

1.  **Is it DNS?** (`dig`)
2.  **Is the host up?** (`ping` - note: might be blocked)
3.  **Is the port open?** (`nc -vz` or `telnet`)
4.  **Is the service failing?** (`curl -v`)
5.  **Is it a firewall?** (Check Cloud SG/NACL or local `iptables`/`ufw`)
