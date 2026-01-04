# Ansible Fundamentals

## What is Ansible?

Ansible is an **agentless automation tool** for configuration management, application deployment, and orchestration. Unlike Chef or Puppet, Ansible doesn't require installing agents on target machines—it connects via **SSH** and pushes configurations.

### Why Ansible?

| Feature | Benefit |
|---------|---------|
| **Agentless** | No software to install on remote servers |
| **YAML-based** | Human-readable playbooks |
| **Idempotent** | Safe to run multiple times (same result) |
| **Push-based** | You control when changes happen |
| **Massive Ecosystem** | 1000s of community modules |

---

## Core Concepts

### Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      CONTROL NODE (Your Mac)                  │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────┐  │
│  │  Inventory  │  │  Playbook   │  │  ansible.cfg         │  │
│  │  (hosts)    │  │  (tasks)    │  │  (configuration)     │  │
│  └─────────────┘  └─────────────┘  └──────────────────────┘  │
│                           │ SSH                               │
└───────────────────────────┼──────────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────────────┐
│                      MANAGED NODES                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │  Web Server │  │  DB Server  │  │  App Server             │ │
│  │  (Ubuntu)   │  │  (CentOS)   │  │  (Debian)               │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

### 1. Inventory

The **inventory** defines the hosts Ansible will manage.

```ini
# inventory.ini (INI format)

# Single hosts
playground-vm

# Groups
[webservers]
web1.example.com
web2.example.com

[databases]
db1.example.com

# Group variables
[webservers:vars]
ansible_user=ubuntu
http_port=80

# Nested groups
[production:children]
webservers
databases
```

### 2. Playbooks

A **playbook** is a YAML file defining automation tasks.

```yaml
# setup_webserver.yml
---
- name: Configure Web Servers
  hosts: webservers
  become: yes  # Run as sudo

  vars:
    app_name: myapp
    http_port: 80

  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
        update_cache: yes

    - name: Start nginx service
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Copy nginx config
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/sites-available/{{ app_name }}
      notify: Restart nginx

  handlers:
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
```

### 3. Modules

**Modules** are the building blocks of Ansible tasks. Each module handles a specific function.

| Module | Purpose | Example |
|--------|---------|---------|
| `apt`/`yum` | Package management | Install nginx |
| `service` | Service management | Start/stop services |
| `copy` | Copy files | Copy config files |
| `template` | Jinja2 templates | Dynamic config files |
| `file` | File/directory management | Create directories |
| `user` | User management | Create users |
| `git` | Git operations | Clone repositories |
| `docker_container` | Docker management | Run containers |

### 4. Variables

Variables make playbooks reusable.

```yaml
# Variables in playbook
vars:
  app_port: 8080

# Variable files
- name: Load variables
  hosts: all
  vars_files:
    - vars/common.yml
    - vars/{{ environment }}.yml

# Command line
# ansible-playbook playbook.yml -e "app_port=9000"
```

**Variable Precedence** (lowest to highest):
1. Role defaults
2. Inventory variables
3. Playbook vars
4. Role vars
5. Task vars
6. Extra vars (`-e`)

### 5. Templates (Jinja2)

Templates allow dynamic configuration files.

```jinja2
{# templates/nginx.conf.j2 #}
server {
    listen {{ http_port }};
    server_name {{ ansible_hostname }};
    
    location / {
        proxy_pass http://127.0.0.1:{{ app_port }};
    }
    
    {% if enable_ssl %}
    listen 443 ssl;
    ssl_certificate {{ ssl_cert_path }};
    {% endif %}
}
```

### 6. Roles

**Roles** organize playbooks into reusable components.

```
roles/
└── webserver/
    ├── tasks/
    │   └── main.yml       # Main tasks
    ├── handlers/
    │   └── main.yml       # Handlers
    ├── templates/
    │   └── nginx.conf.j2  # Templates
    ├── files/
    │   └── index.html     # Static files
    ├── vars/
    │   └── main.yml       # Role variables
    ├── defaults/
    │   └── main.yml       # Default variables
    └── meta/
        └── main.yml       # Role metadata
```

Use roles in a playbook:
```yaml
---
- hosts: webservers
  roles:
    - webserver
    - database
```

---

## Hands-On Lab

### Setup

First, ensure you have an OrbStack VM running:

```bash
# Create a VM if you haven't
orb create ubuntu:22.04 playground-vm

# Verify SSH access
ssh playground-vm "echo 'Connected!'"
```

### Exercise 1: Ad-hoc Commands (10 mins)

```bash
# Create inventory file
cd ~/LocalOps/playground/ansible
cat > inventory.ini << 'EOF'
[lab]
playground-vm
EOF

# Test connection
ansible -i inventory.ini all -m ping

# Run ad-hoc commands
ansible -i inventory.ini all -m shell -a "uptime"
ansible -i inventory.ini all -m apt -a "name=htop state=present" --become
```

### Exercise 2: Your First Playbook (15 mins)

Create `setup.yml`:

```yaml
---
- name: Basic Server Setup
  hosts: lab
  become: yes

  vars:
    packages:
      - vim
      - git
      - curl
      - htop

  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install useful packages
      apt:
        name: "{{ packages }}"
        state: present

    - name: Create devops user
      user:
        name: devops
        shell: /bin/bash
        groups: sudo
        append: yes
        create_home: yes

    - name: Set timezone
      timezone:
        name: UTC
```

Run it:
```bash
ansible-playbook -i inventory.ini setup.yml
```

### Exercise 3: Deploy a Web Application (25 mins)

Create the directory structure:
```bash
mkdir -p templates files
```

Create `files/index.html`:
```html
<!DOCTYPE html>
<html>
<head>
    <title>Ansible Deployed!</title>
    <style>
        body { font-family: sans-serif; text-align: center; padding: 50px; }
        h1 { color: #2ecc71; }
    </style>
</head>
<body>
    <h1>🚀 Hello from Ansible!</h1>
    <p>This page was deployed automatically.</p>
</body>
</html>
```

Create `templates/nginx.conf.j2`:
```jinja2
server {
    listen {{ http_port }};
    server_name _;
    
    root /var/www/{{ app_name }};
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

Create `deploy_web.yml`:
```yaml
---
- name: Deploy Web Application
  hosts: lab
  become: yes

  vars:
    app_name: mywebapp
    http_port: 80

  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
        update_cache: yes

    - name: Create web directory
      file:
        path: /var/www/{{ app_name }}
        state: directory
        mode: '0755'

    - name: Copy index.html
      copy:
        src: files/index.html
        dest: /var/www/{{ app_name }}/index.html
        mode: '0644'

    - name: Configure nginx
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/sites-available/{{ app_name }}
      notify: Reload nginx

    - name: Enable site
      file:
        src: /etc/nginx/sites-available/{{ app_name }}
        dest: /etc/nginx/sites-enabled/{{ app_name }}
        state: link
      notify: Reload nginx

    - name: Remove default site
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent
      notify: Reload nginx

    - name: Ensure nginx is running
      service:
        name: nginx
        state: started
        enabled: yes

  handlers:
    - name: Reload nginx
      service:
        name: nginx
        state: reloaded
```

Run the playbook:
```bash
ansible-playbook -i inventory.ini deploy_web.yml

# Test it - since OrbStack shares network, use the VM hostname
curl http://playground-vm
```

---

## Advanced Topics

### Ansible Vault (Secrets Management)

```bash
# Encrypt a file
ansible-vault create secrets.yml

# Encrypt existing file
ansible-vault encrypt vars.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Run playbook with vault
ansible-playbook playbook.yml --ask-vault-pass
```

### Conditionals and Loops

```yaml
tasks:
  # Conditional
  - name: Install Apache (Debian)
    apt:
      name: apache2
    when: ansible_os_family == "Debian"

  - name: Install Apache (RedHat)
    yum:
      name: httpd
    when: ansible_os_family == "RedHat"

  # Loop
  - name: Create multiple users
    user:
      name: "{{ item.name }}"
      groups: "{{ item.groups }}"
    loop:
      - { name: 'alice', groups: 'sudo' }
      - { name: 'bob', groups: 'docker' }
```

---

## Common Commands

```bash
# Syntax check
ansible-playbook playbook.yml --syntax-check

# Dry run (check mode)
ansible-playbook playbook.yml --check

# Show what would change
ansible-playbook playbook.yml --diff

# Limit to specific hosts
ansible-playbook playbook.yml --limit "web1"

# List tasks without executing
ansible-playbook playbook.yml --list-tasks

# Start at specific task
ansible-playbook playbook.yml --start-at-task="Install nginx"
```

---

## Further Learning

1. **Official Docs**: [docs.ansible.com](https://docs.ansible.com/)
2. **Ansible Galaxy**: [galaxy.ansible.com](https://galaxy.ansible.com/) (community roles)
3. **Learning Path**: [Red Hat Ansible Basics](https://www.redhat.com/en/services/training/do007-ansible-essentials-simplicity-automation-technical-overview)
