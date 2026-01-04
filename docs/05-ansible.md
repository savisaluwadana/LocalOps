# Ansible In-Depth Theory

## Configuration Management Fundamentals

### The Configuration Problem

Without automation:
- **Snowflake servers**: Each server configured differently
- **Configuration drift**: Systems diverge from desired state over time
- **Undocumented changes**: No record of what was done
- **Scaling issues**: Manual work doesn't scale
- **Human error**: Mistakes in repetitive tasks

### How Ansible Solves This

Ansible is **agentless** and **push-based**:
- No software to install on managed nodes
- Uses SSH (Linux) or WinRM (Windows)
- You run commands from a control node
- Idempotent (safe to run multiple times)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        ANSIBLE ARCHITECTURE                                   │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│   CONTROL NODE (Your Mac/Workstation)                                        │
│   ┌───────────────────────────────────────────────────────────────────────┐  │
│   │                                                                        │  │
│   │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────────┐  │  │
│   │  │  Playbook  │  │  Inventory │  │   Roles    │  │  ansible.cfg   │  │  │
│   │  │  (.yml)    │  │  (hosts)   │  │ (reusable) │  │ (config)       │  │  │
│   │  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └────────────────┘  │  │
│   │        │               │               │                              │  │
│   │        └───────────────┴───────────────┘                              │  │
│   │                        │                                               │  │
│   │                        ▼                                               │  │
│   │              ┌─────────────────┐                                       │  │
│   │              │  Ansible Engine │                                       │  │
│   │              │  - Parse YAML   │                                       │  │
│   │              │  - Load modules │                                       │  │
│   │              │  - Manage SSH   │                                       │  │
│   │              └────────┬────────┘                                       │  │
│   │                       │                                                │  │
│   └───────────────────────┼────────────────────────────────────────────────┘  │
│                           │ SSH Connection                                    │
│                           ▼                                                   │
│   ┌───────────────────────────────────────────────────────────────────────┐  │
│   │                    MANAGED NODES (Target Servers)                      │  │
│   │                                                                        │  │
│   │  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                  │  │
│   │  │   Web 1     │   │   Web 2     │   │   Database  │                  │  │
│   │  │  (Ubuntu)   │   │  (Ubuntu)   │   │  (CentOS)   │                  │  │
│   │  └─────────────┘   └─────────────┘   └─────────────┘                  │  │
│   │                                                                        │  │
│   │  No agents needed - just SSH access!                                   │  │
│   └───────────────────────────────────────────────────────────────────────┘  │
│                                                                               │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Inventory Deep Dive

### Static Inventory

```ini
# inventory/production.ini

# Ungrouped hosts
mail.example.com

# Web servers
[webservers]
web1.example.com ansible_host=192.168.1.10
web2.example.com ansible_host=192.168.1.11
web3.example.com ansible_host=192.168.1.12

# Database servers
[databases]
db1.example.com ansible_host=192.168.1.20 mysql_port=3306
db2.example.com ansible_host=192.168.1.21 mysql_port=3306

# Group children
[production:children]
webservers
databases

# Group variables
[webservers:vars]
ansible_user=deploy
http_port=80
max_connections=1000

[databases:vars]
ansible_user=dbadmin
backup_enabled=true

# All hosts variables
[all:vars]
ansible_python_interpreter=/usr/bin/python3
ntp_server=time.example.com
```

### Dynamic Inventory

For cloud environments, use dynamic inventory:

```python
#!/usr/bin/env python3
# inventory/dynamic.py

import json
import subprocess

def get_inventory():
    # Example: Get Docker containers
    result = subprocess.run(
        ['docker', 'ps', '--format', '{{.Names}}'],
        capture_output=True, text=True
    )
    containers = result.stdout.strip().split('\n')
    
    inventory = {
        '_meta': {'hostvars': {}},
        'containers': {
            'hosts': containers,
            'vars': {'ansible_connection': 'docker'}
        }
    }
    
    return json.dumps(inventory, indent=2)

if __name__ == '__main__':
    print(get_inventory())
```

---

## Playbook Structure

### Complete Playbook Anatomy

```yaml
---
# Playbook: deploy_webapp.yml
# Description: Deploy a complete web application

# Play 1: Prepare all servers
- name: Prepare all servers
  hosts: all
  become: yes
  gather_facts: yes  # Collect system info

  vars:
    base_packages:
      - vim
      - git
      - curl
      - htop

  pre_tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

  tasks:
    - name: Install base packages
      apt:
        name: "{{ base_packages }}"
        state: present

    - name: Configure timezone
      timezone:
        name: UTC

  handlers:
    - name: Restart chrony
      service:
        name: chrony
        state: restarted

# Play 2: Configure web servers
- name: Configure web servers
  hosts: webservers
  become: yes
  serial: 1  # Rolling deployment, one at a time

  vars_files:
    - vars/webapp.yml
    - "vars/{{ environment }}.yml"

  roles:
    - role: common
    - role: nginx
      nginx_worker_processes: auto
    - role: nodejs
      nodejs_version: "18.x"

  tasks:
    - name: Deploy application
      git:
        repo: "{{ git_repo }}"
        dest: /var/www/app
        version: "{{ git_branch }}"
      notify: Restart application

    - name: Install npm dependencies
      npm:
        path: /var/www/app
        state: present

    - name: Run database migrations
      command: npm run migrate
      args:
        chdir: /var/www/app
      run_once: true  # Only run on first host

  handlers:
    - name: Restart application
      systemd:
        name: webapp
        state: restarted

  post_tasks:
    - name: Verify application is running
      uri:
        url: "http://localhost:{{ http_port }}/health"
        status_code: 200
      register: health_check
      retries: 5
      delay: 10
      until: health_check.status == 200

# Play 3: Configure database
- name: Configure database servers
  hosts: databases
  become: yes

  roles:
    - role: postgresql
      postgresql_version: 15
      postgresql_databases:
        - name: webapp
          owner: appuser
      postgresql_users:
        - name: appuser
          password: "{{ vault_db_password }}"
```

---

## Modules Reference

### File Management

```yaml
tasks:
  # Copy file from control node
  - name: Copy configuration file
    copy:
      src: files/nginx.conf
      dest: /etc/nginx/nginx.conf
      owner: root
      group: root
      mode: '0644'
      backup: yes  # Create backup of existing
    notify: Reload nginx

  # Use template with variables
  - name: Deploy application config
    template:
      src: templates/app.conf.j2
      dest: /etc/app/config.yaml
      owner: app
      group: app
      mode: '0640'
      validate: /usr/bin/app --check-config %s

  # Create directory structure
  - name: Create application directories
    file:
      path: "{{ item }}"
      state: directory
      owner: app
      group: app
      mode: '0755'
    loop:
      - /var/www/app
      - /var/www/app/logs
      - /var/www/app/temp

  # Manage symlinks
  - name: Create current release symlink
    file:
      src: "/var/www/releases/{{ release_version }}"
      dest: /var/www/current
      state: link

  # Synchronize directories (rsync)
  - name: Sync application files
    synchronize:
      src: app/
      dest: /var/www/app/
      delete: yes
      rsync_opts:
        - "--exclude=.git"
        - "--exclude=node_modules"
```

### Package Management

```yaml
tasks:
  # Debian/Ubuntu
  - name: Install packages (apt)
    apt:
      name:
        - nginx
        - python3-pip
        - postgresql-client
      state: present
      update_cache: yes

  # RHEL/CentOS
  - name: Install packages (yum)
    yum:
      name:
        - httpd
        - python3-pip
      state: present
    when: ansible_os_family == "RedHat"

  # Python packages
  - name: Install Python packages
    pip:
      name:
        - flask
        - gunicorn
        - psycopg2-binary
      virtualenv: /opt/app/venv
      virtualenv_python: python3

  # Node.js packages
  - name: Install npm packages globally
    npm:
      name: pm2
      global: yes

  # Add repository
  - name: Add Docker repository
    apt_repository:
      repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable
      state: present
```

### Service Management

```yaml
tasks:
  # Manage systemd services
  - name: Ensure nginx is running
    systemd:
      name: nginx
      state: started
      enabled: yes
      daemon_reload: yes

  # Create custom service
  - name: Create application service file
    copy:
      dest: /etc/systemd/system/webapp.service
      content: |
        [Unit]
        Description=Web Application
        After=network.target

        [Service]
        Type=simple
        User=app
        WorkingDirectory=/var/www/app
        ExecStart=/opt/app/venv/bin/gunicorn -b 0.0.0.0:8000 app:app
        Restart=always
        RestartSec=5

        [Install]
        WantedBy=multi-user.target
    notify: Restart webapp

handlers:
  - name: Restart webapp
    systemd:
      name: webapp
      state: restarted
      daemon_reload: yes
```

---

## Jinja2 Templates

### Template Syntax

```jinja2
{# templates/nginx.conf.j2 #}

# Managed by Ansible - DO NOT EDIT MANUALLY
# Last updated: {{ ansible_date_time.iso8601 }}

user {{ nginx_user | default('www-data') }};
worker_processes {{ nginx_worker_processes | default('auto') }};
pid /run/nginx.pid;

events {
    worker_connections {{ nginx_worker_connections | default(1024) }};
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Upstream backends
    upstream app_servers {
      {% for server in groups['webservers'] %}
        server {{ hostvars[server]['ansible_host'] }}:{{ http_port }};
      {% endfor %}
    }

    # Server blocks
    {% for site in nginx_sites %}
    server {
        listen 80;
        server_name {{ site.domain }};

        {% if site.ssl_enabled | default(false) %}
        listen 443 ssl;
        ssl_certificate /etc/ssl/{{ site.domain }}.crt;
        ssl_certificate_key /etc/ssl/{{ site.domain }}.key;
        {% endif %}

        location / {
            proxy_pass http://app_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        {% if site.static_files is defined %}
        location /static {
            alias {{ site.static_files }};
            expires 30d;
        }
        {% endif %}
    }
    {% endfor %}
}
```

### Jinja2 Filters

```yaml
tasks:
  - name: Demonstrate filters
    debug:
      msg: |
        # String manipulation
        Upper: {{ "hello" | upper }}  # HELLO
        Lower: {{ "HELLO" | lower }}  # hello
        Title: {{ "hello world" | title }}  # Hello World
        Replace: {{ "hello" | replace("l", "L") }}  # heLLo
        
        # Lists
        First: {{ [1, 2, 3] | first }}  # 1
        Last: {{ [1, 2, 3] | last }}  # 3
        Length: {{ [1, 2, 3] | length }}  # 3
        Join: {{ ["a", "b", "c"] | join(",") }}  # a,b,c
        
        # Defaults
        Value: {{ undefined_var | default("fallback") }}
        
        # Conditionals
        Ternary: {{ true | ternary("yes", "no") }}  # yes
        
        # JSON/YAML
        To JSON: {{ {"key": "value"} | to_json }}
        To YAML: {{ {"key": "value"} | to_nice_yaml }}
        
        # Hashing
        MD5: {{ "password" | hash("md5") }}
        SHA512: {{ "password" | password_hash("sha512") }}
```

---

## Complete Deployment Example

### Project Structure

```
ansible-project/
├── ansible.cfg
├── inventory/
│   ├── production/
│   │   ├── hosts.ini
│   │   └── group_vars/
│   │       ├── all.yml
│   │       ├── webservers.yml
│   │       └── databases.yml
│   └── staging/
│       └── hosts.ini
├── playbooks/
│   ├── site.yml
│   ├── deploy.yml
│   └── rollback.yml
├── roles/
│   ├── common/
│   ├── nginx/
│   ├── nodejs/
│   └── postgresql/
├── templates/
├── files/
└── vars/
    └── vault.yml
```

### ansible.cfg

```ini
[defaults]
inventory = inventory/production
roles_path = roles
retry_files_enabled = False
host_key_checking = False
callback_whitelist = profile_tasks

[privilege_escalation]
become = True
become_method = sudo
become_user = root

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
```

### Main Playbook

```yaml
# playbooks/site.yml
---
- name: Apply common configuration
  hosts: all
  roles:
    - common

- name: Configure web servers
  hosts: webservers
  roles:
    - nginx
    - nodejs

- name: Configure database servers
  hosts: databases
  roles:
    - postgresql

- name: Deploy application
  import_playbook: deploy.yml
```

### Running Playbooks

```bash
# Syntax check
ansible-playbook playbooks/site.yml --syntax-check

# Dry run (check mode)
ansible-playbook playbooks/site.yml --check --diff

# Run on staging
ansible-playbook -i inventory/staging playbooks/site.yml

# Run with vault password
ansible-playbook playbooks/site.yml --ask-vault-pass

# Limit to specific hosts
ansible-playbook playbooks/site.yml --limit webservers

# Start at specific task
ansible-playbook playbooks/site.yml --start-at-task="Deploy application"

# Run with extra variables
ansible-playbook playbooks/deploy.yml -e "version=v1.2.3 environment=production"
```
