# Linux Playground (OrbStack)

This directory contains instructions and scripts to manage your local Linux Virtual Machines using OrbStack.

## Quick Start

### 1. Create a VM
To create a fresh Ubuntu 22.04 machine named `playground-vm`:

```bash
orb create ubuntu:22.04 playground-vm
```

### 2. Connect
You can SSH into it directly (no password needed by default):

```bash
ssh playground-vm
```

### 3. Cleanup
To delete the VM when you are done:

```bash
orb delete playground-vm
```

## Advanced Usage

### Using with Ansible
Since `ssh playground-vm` works natively, you can use `playground-vm` as a hostname in your Ansible inventory!
