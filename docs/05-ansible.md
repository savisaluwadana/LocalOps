# Ansible Complete Theory Guide

## Table of Contents

1. [What is Configuration Management?](#what-is-configuration-management)
2. [Understanding Ansible](#understanding-ansible)
3. [Ansible Architecture Explained](#ansible-architecture-explained)
4. [The Inventory System](#the-inventory-system)
5. [Playbooks Deep Dive](#playbooks-deep-dive)
6. [Modules Explained](#modules-explained)
7. [Variables and Facts](#variables-and-facts)
8. [Jinja2 Templating](#jinja2-templating)
9. [Roles and Reusability](#roles-and-reusability)
10. [Ansible Vault](#ansible-vault)
11. [Best Practices](#best-practices)
12. [Real-World Examples](#real-world-examples)

---

## What is Configuration Management?

### The Problem Before Configuration Management

Imagine you're a system administrator managing 50 servers. Without automation, every time you need to:
- Install software, you SSH into each server manually
- Update a configuration file, you edit it 50 times
- Add a new user, you create the user on each server one by one

This leads to several critical problems:

**1. Snowflake Servers**
Every server becomes unique because small differences accumulate over time. Server A has package version 2.1, Server B has 2.3. Nobody remembers why. This makes troubleshooting nearly impossible because you can't reproduce issues.

**2. Configuration Drift**
Systems gradually diverge from their intended state. Someone makes an "emergency fix" on one server, forgets to document it, and suddenly that server behaves differently from the rest.

**3. Human Error**
Repetitive tasks lead to mistakes. The more times you do something manually, the more likely you are to make an error. Typos, skipped steps, and misconfigurations become inevitable.

**4. No Audit Trail**
When something breaks, you have no way to know what changed or when. "Who modified /etc/nginx/nginx.conf last week?" becomes an unanswerable question.

**5. Scaling Nightmare**
Manual processes don't scale. If it takes 10 minutes to configure one server, 100 servers will take 16 hours of continuous work—assuming zero mistakes.

### What Configuration Management Solves

Configuration management tools allow you to:

| Problem | Solution |
|---------|----------|
| Snowflake servers | Identical configuration applied everywhere |
| Configuration drift | Continuous enforcement of desired state |
| Human error | Automated, tested procedures |
| No audit trail | Version-controlled infrastructure code |
| Scaling issues | Same effort for 1 or 1,000 servers |

### Types of Configuration Management

**Agent-based (Pull Model)**
- A small program (agent) runs on each managed server
- The agent periodically checks with a central server
- Downloads and applies any configuration changes
- Examples: Puppet, Chef, SaltStack

**Agentless (Push Model)**
- No software installed on managed servers
- The control machine connects remotely and pushes changes
- Uses existing SSH or WinRM protocols
- Examples: Ansible

```
PULL MODEL (Puppet/Chef):
┌─────────────┐         ┌─────────────┐
│   Central   │◀────────│   Agent on  │
│   Server    │ Checks  │   Server 1  │
│             │ every   ├─────────────┤
│             │ 30 min  │   Agent on  │
│             │◀────────│   Server 2  │
└─────────────┘         └─────────────┘

PUSH MODEL (Ansible):
┌─────────────┐         ┌─────────────┐
│   Control   │────────▶│   Server 1  │
│   Machine   │   SSH   │  (no agent) │
│             │─────────┼─────────────┤
│  You run:   │   SSH   │   Server 2  │
│  ansible-   │────────▶│  (no agent) │
│  playbook   │         └─────────────┘
└─────────────┘
```

---

## Understanding Ansible

### Why Ansible?

Ansible was created by Michael DeHaan in 2012 with a simple philosophy: **simplicity matters**. Here's why many organizations choose Ansible:

**1. Agentless Architecture**
You don't need to install anything on target servers. If you can SSH to a server, you can manage it with Ansible. This means:
- No agent to maintain, update, or secure
- Immediate deployment—just point and run
- Works with any SSH-accessible system, including network devices

**2. Human-Readable Language**
Ansible uses YAML, which is almost like reading plain English. Compare:

```yaml
# Ansible (easy to read)
- name: Install and start nginx
  apt:
    name: nginx
    state: present
    
- name: Start nginx service
  service:
    name: nginx
    state: started
```

```ruby
# Puppet (requires learning a DSL)
package { 'nginx':
  ensure => installed,
}

service { 'nginx':
  ensure => running,
  require => Package['nginx'],
}
```

**3. Idempotency**
This is a crucial concept. "Idempotent" means you can run the same operation multiple times and always get the same result. Consider this example:

```yaml
- name: Create user alice
  user:
    name: alice
    state: present
```

Running this once creates user alice. Running it 100 more times changes nothing—alice already exists. This makes Ansible safe to run repeatedly without side effects.

**4. No Programming Required**
While Ansible supports complex logic, most tasks need no programming. System administrators who aren't developers can be productive immediately.

### Key Terminology

Understanding Ansible requires knowing these terms:

| Term | Definition | Analogy |
|------|------------|---------|
| **Control Node** | The machine where Ansible runs | Your laptop or a CI/CD server |
| **Managed Node** | A server controlled by Ansible | Any target server |
| **Inventory** | List of managed nodes | Your address book |
| **Playbook** | A YAML file defining tasks | A recipe book |
| **Play** | A set of tasks for a host group | One recipe |
| **Task** | A single action | One step in a recipe |
| **Module** | Code that performs a task | A kitchen tool |
| **Role** | A reusable bundle of tasks | A complete recipe with ingredients |
| **Handler** | A task triggered by changes | A notification system |
| **Facts** | Information gathered from nodes | Automatically collected data |

---

## Ansible Architecture Explained

### How Ansible Works Internally

When you run an Ansible playbook, here's what happens behind the scenes:

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           ANSIBLE EXECUTION FLOW                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   STEP 1: Parse                                                                      │
│   ┌──────────────────────────────────────────────────────────────────────────────┐  │
│   │  Ansible reads your playbook and inventory                                    │  │
│   │  - Validates YAML syntax                                                      │  │
│   │  - Loads variables from all sources                                           │  │
│   │  - Determines which hosts to target                                           │  │
│   └──────────────────────────────────────────────────────────────────────────────┘  │
│                                         │                                            │
│                                         ▼                                            │
│   STEP 2: Generate Python Code                                                       │
│   ┌──────────────────────────────────────────────────────────────────────────────┐  │
│   │  For each task, Ansible:                                                      │  │
│   │  - Finds the appropriate module (e.g., apt, copy, service)                   │  │
│   │  - Combines the module code with your parameters                              │  │
│   │  - Creates a self-contained Python script                                     │  │
│   └──────────────────────────────────────────────────────────────────────────────┘  │
│                                         │                                            │
│                                         ▼                                            │
│   STEP 3: Transfer                                                                   │
│   ┌──────────────────────────────────────────────────────────────────────────────┐  │
│   │  Ansible connects via SSH and:                                                │  │
│   │  - Creates a temporary directory on the target                               │  │
│   │  - Copies the generated Python script                                        │  │
│   │  - Transfers any files needed (templates, files, etc.)                       │  │
│   └──────────────────────────────────────────────────────────────────────────────┘  │
│                                         │                                            │
│                                         ▼                                            │
│   STEP 4: Execute                                                                    │
│   ┌──────────────────────────────────────────────────────────────────────────────┐  │
│   │  On the target server:                                                        │  │
│   │  - Python interpreter runs the script                                        │  │
│   │  - Module performs the actual work                                           │  │
│   │  - Returns JSON result (changed/ok/failed)                                   │  │
│   └──────────────────────────────────────────────────────────────────────────────┘  │
│                                         │                                            │
│                                         ▼                                            │
│   STEP 5: Cleanup                                                                    │
│   ┌──────────────────────────────────────────────────────────────────────────────┐  │
│   │  - Temporary files are removed                                                │  │
│   │  - Results are collected and displayed                                        │  │
│   │  - Any handlers triggered by changes are queued                              │  │
│   └──────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Requirements

**Control Node Requirements:**
- Linux, macOS, or Windows with WSL
- Python 3.9+ installed
- SSH client
- Ansible installed (`pip install ansible`)

**Managed Node Requirements:**
- SSH server running
- Python 3 installed (for most modules)
- User account for Ansible to use
- Sudo privileges (if using `become: yes`)

### Connection Plugins

Ansible isn't limited to SSH. It supports multiple connection methods:

| Plugin | Use Case | Example |
|--------|----------|---------|
| `ssh` | Linux/Unix servers | Default for most servers |
| `winrm` | Windows servers | Windows Server administration |
| `docker` | Docker containers | Container management |
| `local` | Control node itself | Testing, local operations |
| `network_cli` | Network devices | Cisco, Juniper switches |
| `httpapi` | REST APIs | Cloud services, firewalls |

---

## The Inventory System

### What is an Inventory?

The inventory is a list of servers that Ansible manages. Think of it as your address book—it tells Ansible where servers are and how to connect to them.

### Inventory Formats

**INI Format (Simple, Traditional)**

```ini
# inventory/hosts.ini

# Simple host listing
192.168.1.10
server1.example.com

# Groups organize hosts
[webservers]
web1.example.com
web2.example.com
web3.example.com

[databases]
db1.example.com
db2.example.com

# Variables for individual hosts
[webservers]
web1.example.com http_port=80 max_clients=200
web2.example.com http_port=8080 max_clients=100

# Variables for entire groups
[webservers:vars]
ansible_user=deploy
nginx_version=1.18

# Nested groups (groups of groups)
[production:children]
webservers
databases
```

**YAML Format (More Readable for Complex Inventories)**

```yaml
# inventory/hosts.yml
all:
  children:
    production:
      children:
        webservers:
          hosts:
            web1.example.com:
              http_port: 80
              max_clients: 200
            web2.example.com:
              http_port: 8080
              max_clients: 100
          vars:
            ansible_user: deploy
            nginx_version: "1.18"
        
        databases:
          hosts:
            db1.example.com:
            db2.example.com:
          vars:
            ansible_user: dbadmin
            backup_schedule: "0 2 * * *"
    
    staging:
      hosts:
        staging.example.com:
      vars:
        environment: staging
```

### Understanding Host Variables

You can set variables at multiple levels:

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        VARIABLE PRECEDENCE (Lowest to Highest)                       │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   1. Defaults in roles (roles/myrole/defaults/main.yml)                             │
│   2. Inventory group_vars/all                                                        │
│   3. Inventory group_vars/group_name                                                 │
│   4. Inventory host_vars/hostname                                                    │
│   5. Playbook group_vars/all                                                         │
│   6. Playbook group_vars/group_name                                                  │
│   7. Playbook host_vars/hostname                                                     │
│   8. Host facts (gathered from the system)                                          │
│   9. Play vars:                                                                      │
│   10. Play vars_files:                                                               │
│   11. Play vars_prompt:                                                              │
│   12. Task vars:                                                                     │
│   13. set_fact / registered vars                                                     │
│   14. Extra vars (ansible-playbook -e "var=value")  ← HIGHEST PRIORITY              │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

**Example Directory Structure for Variables:**

```
inventory/
├── production/
│   ├── hosts.yml
│   ├── group_vars/
│   │   ├── all.yml           # Variables for ALL hosts
│   │   ├── webservers.yml    # Variables for webservers group
│   │   └── databases.yml     # Variables for databases group
│   └── host_vars/
│       ├── web1.example.com.yml  # Variables for specific host
│       └── db1.example.com.yml
└── staging/
    ├── hosts.yml
    └── group_vars/
        └── all.yml
```

**group_vars/all.yml** (Applies to every host):
```yaml
# Global settings for all hosts
ntp_server: time.example.com
log_level: info
admin_email: ops@example.com
ssh_port: 22
```

**group_vars/webservers.yml** (Only for webservers):
```yaml
# Web server specific settings
http_port: 80
https_port: 443
document_root: /var/www/html
nginx_worker_processes: auto
```

### Inventory Patterns

When running Ansible, you can target specific hosts using patterns:

```bash
# All hosts
ansible all -m ping

# Single host
ansible web1.example.com -m ping

# Group
ansible webservers -m ping

# Multiple groups (OR)
ansible 'webservers:databases' -m ping

# Intersection (AND)
ansible 'webservers:&production' -m ping

# Exclusion
ansible 'webservers:!web3.example.com' -m ping

# Wildcard
ansible 'web*.example.com' -m ping

# Regex (must start with ~)
ansible '~web[0-9]+.example.com' -m ping

# Range
ansible 'web[1:5].example.com' -m ping  # web1 through web5
```

---

## Playbooks Deep Dive

### What is a Playbook?

A playbook is a YAML file that describes the desired state of your systems. It's like a recipe:
- **Ingredients** = Variables and files
- **Steps** = Tasks
- **Recipe** = The playbook itself

### Playbook Structure Explained

```yaml
---
# A playbook can contain multiple plays
# Each play targets a group of hosts

# PLAY 1
- name: Configure web servers        # Human-readable description
  hosts: webservers                  # Which hosts to target
  become: yes                        # Run as root (sudo)
  gather_facts: yes                  # Collect system information
  
  vars:                              # Variables for this play
    app_user: www-data
    app_port: 8080
  
  vars_files:                        # External variable files
    - vars/common.yml
    - "vars/{{ environment }}.yml"
  
  pre_tasks:                         # Tasks to run BEFORE roles
    - name: Update package cache
      apt:
        update_cache: yes
  
  roles:                             # Reusable role includes
    - common
    - nginx
  
  tasks:                             # Main task list
    - name: Create application directory
      file:
        path: /var/www/app
        state: directory
  
  handlers:                          # Triggered by notify
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
  
  post_tasks:                        # Tasks to run AFTER everything
    - name: Verify service is running
      uri:
        url: http://localhost:8080/health
        status_code: 200
```

### Understanding Tasks

A task is a single action. Each task uses a module to perform work:

```yaml
tasks:
  # Basic task structure
  - name: Descriptive name of what this task does
    module_name:
      parameter1: value1
      parameter2: value2
    
  # Real example: Install packages
  - name: Install required packages
    apt:
      name:
        - nginx
        - python3
        - git
      state: present        # present = install, absent = remove
      update_cache: yes     # Run apt update first
    
  # Task with become (run as different user)
  - name: Run command as postgres user
    command: createdb myapp
    become: yes
    become_user: postgres
    
  # Task with conditions
  - name: Install apt packages (Debian/Ubuntu only)
    apt:
      name: nginx
      state: present
    when: ansible_os_family == "Debian"
    
  # Task with loops
  - name: Create multiple users
    user:
      name: "{{ item.name }}"
      groups: "{{ item.groups }}"
    loop:
      - { name: alice, groups: developers }
      - { name: bob, groups: developers }
      - { name: charlie, groups: admins }
    
  # Task with error handling
  - name: Try to start service (may fail on first run)
    service:
      name: myapp
      state: started
    register: result
    ignore_errors: yes
    
  - name: Handle service not existing
    debug:
      msg: "Service not installed yet, will be configured later"
    when: result is failed
```

### Conditionals Explained

The `when` statement controls if a task runs:

```yaml
tasks:
  # Simple condition
  - name: Run only on Ubuntu
    apt:
      name: nginx
    when: ansible_distribution == "Ubuntu"
  
  # Multiple conditions (AND)
  - name: Run on Ubuntu 22.04 only
    apt:
      name: nginx
    when:
      - ansible_distribution == "Ubuntu"
      - ansible_distribution_major_version == "22"
  
  # OR condition
  - name: Install on Debian or Ubuntu
    apt:
      name: nginx
    when: ansible_os_family == "Debian" or ansible_distribution == "Ubuntu"
  
  # Using variables
  - name: Run if feature is enabled
    template:
      src: feature.conf.j2
      dest: /etc/app/feature.conf
    when: enable_feature | default(false)
  
  # Check if variable is defined
  - name: Use custom port if defined
    lineinfile:
      path: /etc/app/config
      line: "PORT={{ custom_port }}"
    when: custom_port is defined
  
  # Based on previous task result
  - name: Restart service if config changed
    service:
      name: nginx
      state: restarted
    when: config_task.changed
```

### Loops Explained

Ansible supports various loop constructs:

```yaml
tasks:
  # Simple loop (recommended modern syntax)
  - name: Create users
    user:
      name: "{{ item }}"
      state: present
    loop:
      - alice
      - bob
      - charlie
  
  # Loop with dictionaries
  - name: Create users with groups
    user:
      name: "{{ item.name }}"
      groups: "{{ item.groups }}"
      shell: "{{ item.shell | default('/bin/bash') }}"
    loop:
      - { name: alice, groups: developers }
      - { name: bob, groups: developers, shell: /bin/zsh }
      - { name: charlie, groups: admins }
  
  # Loop from variable
  - name: Install packages from list
    apt:
      name: "{{ item }}"
      state: present
    loop: "{{ packages_to_install }}"
  
  # Loop with index
  - name: Create numbered files
    file:
      path: "/tmp/file{{ index }}.txt"
      state: touch
    loop: "{{ items }}"
    loop_control:
      index_var: index
      label: "{{ item.name }}"  # Custom output label
  
  # Nested loops
  - name: Create user directories
    file:
      path: "/home/{{ item.0 }}/{{ item.1 }}"
      state: directory
      owner: "{{ item.0 }}"
    loop: "{{ users | product(directories) | list }}"
    vars:
      users: [alice, bob]
      directories: [downloads, documents, projects]
```

### Handlers Explained

Handlers are tasks that only run when notified by another task:

```yaml
tasks:
  - name: Update nginx configuration
    template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify: Restart nginx        # Notify handler by name
  
  - name: Update nginx vhost
    template:
      src: vhost.conf.j2
      dest: /etc/nginx/sites-enabled/mysite.conf
    notify: Reload nginx         # Different handler
  
  - name: Install SSL certificate
    copy:
      src: ssl/
      dest: /etc/ssl/
    notify:
      - Restart nginx            # Multiple handlers
      - Verify nginx config

handlers:
  - name: Restart nginx
    service:
      name: nginx
      state: restarted
    listen: "restart web server"  # Can use listen for multiple names
  
  - name: Reload nginx
    service:
      name: nginx
      state: reloaded
  
  - name: Verify nginx config
    command: nginx -t
```

**Why Handlers?**
- They only run once, even if notified multiple times
- They run at the end of all tasks (or when `meta: flush_handlers` is called)
- They prevent unnecessary service restarts

---

## Modules Explained

### What are Modules?

Modules are units of code that Ansible executes on target hosts. They're like specialized tools, each designed for a specific task.

### Module Categories

**File Modules:**
```yaml
# file - Manage files and directories
- name: Create directory with specific permissions
  file:
    path: /var/www/app
    state: directory
    owner: www-data
    group: www-data
    mode: '0755'
    recurse: yes

# copy - Copy files from control node to target
- name: Copy configuration file
  copy:
    src: files/app.conf          # Local file
    dest: /etc/app/app.conf      # Remote destination
    owner: root
    mode: '0644'
    backup: yes                  # Create backup before overwriting

# template - Process Jinja2 templates
- name: Deploy config from template
  template:
    src: templates/app.conf.j2   # Template with variables
    dest: /etc/app/app.conf
    validate: '/usr/bin/app --validate %s'  # Validate before deploying

# lineinfile - Manage single lines in files
- name: Ensure SSH allows password authentication
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^PasswordAuthentication'
    line: 'PasswordAuthentication no'
    state: present

# blockinfile - Manage blocks of text
- name: Add custom configuration block
  blockinfile:
    path: /etc/app/config
    marker: "# {mark} ANSIBLE MANAGED BLOCK"
    block: |
      setting1=value1
      setting2=value2
      setting3=value3
```

**Package Modules:**
```yaml
# apt - Debian/Ubuntu package management
- name: Install packages on Ubuntu
  apt:
    name:
      - nginx
      - postgresql
      - python3-pip
    state: present
    update_cache: yes
    cache_valid_time: 3600      # Don't update if updated in last hour

# yum - RHEL/CentOS package management
- name: Install packages on CentOS
  yum:
    name:
      - httpd
      - mariadb-server
    state: present

# package - Generic (auto-detects package manager)
- name: Install package (any distro)
  package:
    name: git
    state: present

# pip - Python packages
- name: Install Python libraries
  pip:
    name:
      - flask
      - gunicorn
      - requests
    virtualenv: /opt/app/venv
    state: present
```

**Service Modules:**
```yaml
# service - Generic service management
- name: Start and enable nginx
  service:
    name: nginx
    state: started
    enabled: yes

# systemd - Systemd-specific features
- name: Manage systemd service
  systemd:
    name: myapp
    state: restarted
    enabled: yes
    daemon_reload: yes          # Reload systemd if unit file changed
```

**User/Group Modules:**
```yaml
# user - Manage user accounts
- name: Create application user
  user:
    name: appuser
    comment: "Application Service Account"
    uid: 1050
    group: appgroup
    groups:
      - docker
      - developers
    shell: /bin/bash
    home: /home/appuser
    create_home: yes
    password: "{{ password_hash }}"
    state: present

# group - Manage groups
- name: Create application group
  group:
    name: appgroup
    gid: 1050
    state: present
```

**Command/Shell Modules:**
```yaml
# command - Run commands (safer, no shell features)
- name: Run a command
  command: /usr/bin/app --version
  register: app_version
  changed_when: false           # This command doesn't change anything

# shell - Run commands with shell features
- name: Run with shell features (pipes, redirects)
  shell: cat /var/log/app.log | grep ERROR | wc -l
  register: error_count
  args:
    executable: /bin/bash

# script - Run a local script on remote
- name: Run deployment script
  script: files/deploy.sh
  args:
    creates: /var/www/app/deployed.flag  # Don't run if file exists
```

---

## Variables and Facts

### Understanding Variables

Variables make your playbooks dynamic and reusable. Instead of hardcoding values, you use variables:

```yaml
# Without variables (not reusable)
- name: Install nginx
  apt:
    name: nginx-1.18.0
    state: present

# With variables (reusable)
- name: Install nginx
  apt:
    name: "nginx-{{ nginx_version }}"
    state: present
```

### Where Variables Come From

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                        VARIABLE SOURCES                                              │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│   INVENTORY                                                                          │
│   ├── Inline: web1 http_port=80                                                     │
│   ├── group_vars/webservers.yml                                                     │
│   └── host_vars/web1.example.com.yml                                                │
│                                                                                      │
│   PLAYBOOK                                                                           │
│   ├── vars: section                                                                  │
│   ├── vars_files: external YAML files                                               │
│   └── vars_prompt: interactive prompts                                              │
│                                                                                      │
│   ROLES                                                                              │
│   ├── roles/myrole/defaults/main.yml (lowest priority)                              │
│   └── roles/myrole/vars/main.yml (higher priority)                                  │
│                                                                                      │
│   RUNTIME                                                                            │
│   ├── set_fact: dynamically set during play                                         │
│   ├── register: capture command output                                              │
│   └── -e / --extra-vars: command line (highest priority)                            │
│                                                                                      │
│   FACTS (Automatic)                                                                  │
│   └── ansible_* variables collected from systems                                    │
│                                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Facts Explained

Facts are variables automatically discovered about your systems:

```yaml
- name: Display system facts
  debug:
    msg: |
      Hostname: {{ ansible_hostname }}
      FQDN: {{ ansible_fqdn }}
      OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
      Kernel: {{ ansible_kernel }}
      Architecture: {{ ansible_architecture }}
      CPUs: {{ ansible_processor_vcpus }}
      Memory: {{ ansible_memtotal_mb }} MB
      IP Addresses: {{ ansible_all_ipv4_addresses }}
      Default IPv4: {{ ansible_default_ipv4.address }}
```

**Common Facts You'll Use:**

| Fact | Description | Example Value |
|------|-------------|---------------|
| `ansible_hostname` | Short hostname | `web1` |
| `ansible_fqdn` | Fully qualified name | `web1.example.com` |
| `ansible_distribution` | OS name | `Ubuntu` |
| `ansible_distribution_version` | OS version | `22.04` |
| `ansible_os_family` | OS family | `Debian` |
| `ansible_default_ipv4.address` | Primary IP | `192.168.1.10` |
| `ansible_memtotal_mb` | Total RAM in MB | `8192` |
| `ansible_processor_vcpus` | CPU count | `4` |
| `ansible_mounts` | Mounted filesystems | List of mounts |

### Using register

The `register` keyword captures task output:

```yaml
- name: Check if application is installed
  command: which app
  register: app_check
  ignore_errors: yes
  changed_when: false

- name: Install application if not found
  apt:
    name: myapp
  when: app_check.rc != 0    # rc = return code

- name: Get application version
  command: app --version
  register: version_output
  changed_when: false

- name: Display version
  debug:
    var: version_output.stdout

# What register captures:
# - stdout: command output
# - stderr: error output
# - rc: return code (0 = success)
# - changed: whether task changed anything
# - failed: whether task failed
```

---

## Jinja2 Templating

### What is Jinja2?

Jinja2 is a templating engine that lets you create dynamic content. Ansible uses Jinja2 for:
- Templates (`.j2` files)
- Variable interpolation in playbooks
- Conditional logic in task parameters

### Basic Syntax

```jinja2
{# This is a comment - not included in output #}

{{ variable }}           {# Variable substitution #}
{% if condition %}        {# Control structures #}
{% for item in list %}    {# Loops #}
{% endif %}
{% endfor %}
```

### Template Examples

**Simple Configuration Template:**

```jinja2
{# templates/nginx.conf.j2 #}

# Ansible managed - DO NOT EDIT MANUALLY
# Generated on {{ ansible_date_time.date }} at {{ ansible_date_time.time }}

user {{ nginx_user | default('www-data') }};
worker_processes {{ ansible_processor_vcpus }};
pid /run/nginx.pid;

events {
    worker_connections {{ nginx_connections | default(1024) }};
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    sendfile on;
    keepalive_timeout {{ nginx_keepalive | default(65) }};

    server {
        listen {{ http_port }};
        server_name {{ server_name }};
        root {{ document_root }};

        location / {
            try_files $uri $uri/ =404;
        }
    }
}
```

**Conditional Sections:**

```jinja2
{# templates/app.conf.j2 #}

[database]
host = {{ db_host }}
port = {{ db_port | default(5432) }}
name = {{ db_name }}
user = {{ db_user }}

{% if db_ssl_enabled | default(false) %}
ssl = true
ssl_ca = /etc/ssl/certs/ca-certificates.crt
{% endif %}

[cache]
{% if cache_enabled | default(true) %}
enabled = true
type = {{ cache_type | default('redis') }}
host = {{ cache_host }}
{% else %}
enabled = false
{% endif %}

[logging]
level = {{ log_level | default('INFO') | upper }}
{% if environment == 'production' %}
format = json
destination = syslog
{% else %}
format = text
destination = file
file_path = /var/log/app/app.log
{% endif %}
```

**Looping Through Data:**

```jinja2
{# templates/hosts.j2 - Generate /etc/hosts #}

127.0.0.1   localhost
::1         localhost ip6-localhost ip6-loopback

# Managed hosts
{% for host in groups['all'] %}
{{ hostvars[host]['ansible_default_ipv4']['address'] }}  {{ hostvars[host]['ansible_hostname'] }} {{ hostvars[host]['ansible_fqdn'] }}
{% endfor %}

# Application servers
{% for server in app_servers %}
{{ server.ip }}  {{ server.hostname }}  # {{ server.role | default('app') }}
{% endfor %}
```

### Jinja2 Filters

Filters transform values:

```jinja2
# String manipulation
{{ "hello" | upper }}                    # HELLO
{{ "HELLO" | lower }}                    # hello
{{ "hello world" | title }}              # Hello World
{{ "hello" | capitalize }}               # Hello
{{ "  hello  " | trim }}                 # hello
{{ "hello" | replace("l", "L") }}        # heLLo

# Default values (VERY IMPORTANT!)
{{ undefined_var | default("fallback") }}
{{ empty_string | default("fallback", true) }}  # true = treat empty as undefined

# Lists
{{ ['a', 'b', 'c'] | join(', ') }}       # a, b, c
{{ [3, 1, 2] | sort }}                   # [1, 2, 3]
{{ [1, 2, 3] | first }}                  # 1
{{ [1, 2, 3] | last }}                   # 3
{{ [1, 2, 3] | length }}                 # 3
{{ [1, 2, 2, 3] | unique }}              # [1, 2, 3]

# Math
{{ 5 | abs }}                            # 5 (absolute value)
{{ 5.7 | round }}                        # 6
{{ 5.7 | int }}                          # 5
{{ 10 | random }}                        # Random 0-9

# Type conversion
{{ "123" | int }}                        # 123 (string to int)
{{ 123 | string }}                       # "123" (int to string)
{{ '{"key": "value"}' | from_json }}     # Dict from JSON
{{ my_dict | to_json }}                  # Dict to JSON
{{ my_dict | to_nice_yaml }}             # Dict to YAML

# Path manipulation
{{ "/path/to/file.txt" | basename }}     # file.txt
{{ "/path/to/file.txt" | dirname }}      # /path/to
{{ "file.tar.gz" | splitext }}           # ['file.tar', '.gz']

# Hashing
{{ "password" | hash('md5') }}           # MD5 hash
{{ "password" | password_hash('sha512') }}  # Password hash

# Conditional
{{ true | ternary('yes', 'no') }}        # yes
{{ value | ternary('exists', 'missing') }}
```

---

## Roles and Reusability

### What are Roles?

Roles are a way to organize playbooks into reusable components. Instead of writing the same nginx configuration in every project, you create an "nginx role" and include it wherever needed.

### Role Structure

```
roles/
└── nginx/
    ├── defaults/
    │   └── main.yml      # Default variables (lowest priority)
    ├── files/
    │   └── index.html    # Static files to copy
    ├── handlers/
    │   └── main.yml      # Handler definitions
    ├── meta/
    │   └── main.yml      # Role metadata, dependencies
    ├── tasks/
    │   └── main.yml      # Main task list
    ├── templates/
    │   └── nginx.conf.j2 # Jinja2 templates
    ├── vars/
    │   └── main.yml      # Role variables (high priority)
    └── README.md         # Documentation
```

### Complete Role Example

**roles/nginx/defaults/main.yml:**
```yaml
---
# Default values - can be overridden by users of this role
nginx_user: www-data
nginx_worker_processes: auto
nginx_worker_connections: 1024
nginx_keepalive_timeout: 65
nginx_gzip_enabled: true
nginx_sites: []
```

**roles/nginx/tasks/main.yml:**
```yaml
---
- name: Install nginx
  apt:
    name: nginx
    state: present
  notify: Start nginx

- name: Create nginx directories
  file:
    path: "{{ item }}"
    state: directory
    owner: root
    group: root
    mode: '0755'
  loop:
    - /etc/nginx/sites-available
    - /etc/nginx/sites-enabled
    - /var/www/html

- name: Deploy nginx configuration
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
    validate: 'nginx -t -c %s'
  notify: Reload nginx

- name: Deploy site configurations
  template:
    src: site.conf.j2
    dest: "/etc/nginx/sites-available/{{ item.name }}"
    owner: root
    mode: '0644'
  loop: "{{ nginx_sites }}"
  notify: Reload nginx

- name: Enable sites
  file:
    src: "/etc/nginx/sites-available/{{ item.name }}"
    dest: "/etc/nginx/sites-enabled/{{ item.name }}"
    state: link
  loop: "{{ nginx_sites }}"
  when: item.enabled | default(true)
  notify: Reload nginx
```

**roles/nginx/handlers/main.yml:**
```yaml
---
- name: Start nginx
  service:
    name: nginx
    state: started
    enabled: yes

- name: Reload nginx
  service:
    name: nginx
    state: reloaded

- name: Restart nginx
  service:
    name: nginx
    state: restarted
```

**Using the Role:**
```yaml
# playbooks/webserver.yml
---
- name: Configure web servers
  hosts: webservers
  become: yes
  
  roles:
    - role: nginx
      nginx_worker_processes: 4
      nginx_sites:
        - name: mysite
          server_name: mysite.example.com
          document_root: /var/www/mysite
          enabled: true
```

---

## Ansible Vault

### What is Ansible Vault?

Ansible Vault encrypts sensitive data like passwords, API keys, and certificates so you can safely store them in version control.

### Using Ansible Vault

**Encrypt a file:**
```bash
# Create encrypted file
ansible-vault create secrets.yml

# Encrypt existing file
ansible-vault encrypt vars/production.yml

# View encrypted file
ansible-vault view secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Decrypt file (remove encryption)
ansible-vault decrypt secrets.yml

# Change password
ansible-vault rekey secrets.yml
```

**Using encrypted files in playbooks:**
```yaml
# playbooks/deploy.yml
---
- name: Deploy application
  hosts: webservers
  become: yes
  
  vars_files:
    - vars/common.yml
    - vars/vault.yml      # Encrypted file
  
  tasks:
    - name: Configure database
      template:
        src: db.conf.j2
        dest: /etc/app/db.conf
      vars:
        db_password: "{{ vault_db_password }}"
```

**Run with vault password:**
```bash
# Prompt for password
ansible-playbook deploy.yml --ask-vault-pass

# Use password file
ansible-playbook deploy.yml --vault-password-file ~/.vault_pass

# Use environment variable
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass ansible-playbook deploy.yml
```

### String-Level Encryption

Instead of encrypting entire files, you can encrypt just specific values:

```bash
# Encrypt a string
ansible-vault encrypt_string 'my_secret_password' --name 'db_password'
```

Output:
```yaml
db_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  66386439653236336462626566653063336164306130...
```

Use in your variables file:
```yaml
# vars/production.yml
database:
  host: db.example.com
  user: appuser
  password: !vault |
    $ANSIBLE_VAULT;1.1;AES256
    66386439653236336462626566653063336164306130...
```

---

## Best Practices

### Playbook Organization

```
ansible-project/
├── ansible.cfg              # Project configuration
├── requirements.yml         # Role dependencies
├── inventory/
│   ├── production/
│   │   ├── hosts.yml
│   │   ├── group_vars/
│   │   │   ├── all.yml
│   │   │   └── webservers.yml
│   │   └── host_vars/
│   └── staging/
├── playbooks/
│   ├── site.yml             # Master playbook
│   ├── webservers.yml
│   ├── databases.yml
│   └── deploy.yml
├── roles/
│   ├── common/
│   ├── nginx/
│   └── postgresql/
├── files/                   # Static files
├── templates/               # Jinja2 templates
└── vars/
    ├── vault.yml           # Encrypted secrets
    └── common.yml
```

### Key Best Practices

1. **Always name your tasks**
   ```yaml
   # Bad
   - apt:
       name: nginx
   
   # Good
   - name: Install nginx web server
     apt:
       name: nginx
   ```

2. **Use meaningful variable names**
   ```yaml
   # Bad
   port: 80
   
   # Good
   nginx_http_port: 80
   ```

3. **Always use state parameter**
   ```yaml
   # Explicit is better
   - apt:
       name: nginx
       state: present    # or absent
   ```

4. **Test in dry-run mode first**
   ```bash
   ansible-playbook site.yml --check --diff
   ```

5. **Use tags for selective runs**
   ```yaml
   - name: Deploy application
     git:
       repo: "{{ app_repo }}"
       dest: /var/www/app
     tags:
       - deploy
       - application
   ```
   ```bash
   ansible-playbook site.yml --tags deploy
   ```

---

## Real-World Examples

### Complete Web Application Deployment

```yaml
---
- name: Deploy web application
  hosts: webservers
  become: yes
  serial: 1                  # Rolling deployment

  vars:
    app_version: "{{ version | default('latest') }}"
    app_user: www-data
    app_path: /var/www/app
    releases_path: /var/www/releases
    keep_releases: 5

  pre_tasks:
    - name: Check if deployment should proceed
      uri:
        url: http://localhost:8080/health
        status_code: 200
      register: pre_deploy_check
      ignore_errors: yes

  tasks:
    - name: Create release directory
      file:
        path: "{{ releases_path }}/{{ app_version }}"
        state: directory
        owner: "{{ app_user }}"

    - name: Download application artifact
      get_url:
        url: "https://artifacts.example.com/app-{{ app_version }}.tar.gz"
        dest: /tmp/app.tar.gz
      notify: Restart application

    - name: Extract application
      unarchive:
        src: /tmp/app.tar.gz
        dest: "{{ releases_path }}/{{ app_version }}"
        remote_src: yes
        owner: "{{ app_user }}"

    - name: Update symlink to new release
      file:
        src: "{{ releases_path }}/{{ app_version }}"
        dest: "{{ app_path }}"
        state: link
      notify: Restart application

    - name: Clean old releases
      shell: |
        cd {{ releases_path }}
        ls -t | tail -n +{{ keep_releases + 1 }} | xargs rm -rf
      changed_when: false

  handlers:
    - name: Restart application
      systemd:
        name: webapp
        state: restarted

  post_tasks:
    - name: Wait for application to be healthy
      uri:
        url: http://localhost:8080/health
        status_code: 200
      register: health
      retries: 10
      delay: 5
      until: health.status == 200

    - name: Notify deployment success
      slack:
        token: "{{ slack_token }}"
        channel: "#deployments"
        msg: "✅ Deployed {{ app_version }} to {{ inventory_hostname }}"
```

This comprehensive guide covers Ansible theory with detailed explanations, examples, and best practices for real-world usage.
