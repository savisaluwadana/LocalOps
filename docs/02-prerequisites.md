# Prerequisites & Installation

We use **OrbStack** as the unified platform for this playground. It is significantly faster and lighter than Docker Desktop + VirtualBox.

## 1. Install OrbStack
- **Download:** [OrbStack Website](https://orbstack.dev/) or via Homebrew:
  ```bash
  brew install orbstack
  ```
- **Setup:** Open OrbStack and follow the setup guide. Ensure **Docker** and **Kubernetes** are enabled in the settings.

## 2. Install CLI Tools
Install the management tools via Homebrew:

```bash
# Infrastructure as Code
brew install terraform

# Configuration Management
brew install ansible

# Kubernetes Interaction
brew install kubectl helm
```

## 3. Verify Setup

1. **Check OrbStack:**
   ```bash
   orb version
   docker version
   kubectl version --client
   ```

2. **Test a Linux Machine:**
   ```bash
   # Create a test machine
   orb create ubuntu:22.04 test-vm
   
   # Jump into it
   ssh test-vm
   # OR
   orb -m test-vm
   ```
