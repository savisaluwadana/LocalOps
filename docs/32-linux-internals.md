# Linux Internals for SREs: The Kernel Deep Dive

## Table of Contents
1.  [The Process State Lifecycle](#the-process-state-lifecycle)
2.  [Memory Management: Virtual vs Physical](#memory-management-virtual-vs-physical)
3.  [The Virtual File System (VFS)](#the-virtual-file-system-vfs)
4.  [Namespaces Implementation](#namespaces-implementation)
5.  [Control Groups (cgroups) v1 vs v2](#control-groups-cgroups-v1-vs-v2)
6.  [eBPF: The Observability Revolution](#ebpf-the-observability-revolution)

---

## The Process State Lifecycle

Understanding standard states is easy. Understanding the "Stuck" states is critical for SREs.

### The States
-   **R (Running)**: Currently using CPU or waiting in runqueue.
-   **S (Interruptible Sleep)**: Waiting for an event (socket, timer). Can be effectively killed (`SIGKILL`).
-   **D (Uninterruptible Sleep)**: Waiting for Hardware I/O (Disk/Network). **Cannot be killed**.
    -   *Scenario*: NFS server died. Process enters `D` state waiting for generic I/O. `kill -9` does nothing because the process isn't checking for signals; it's waiting for the driver callback.
    -   *Fix*: Reboot server or fix hardware.
-   **Z (Zombie)**: Process finished, but parent hasn't read its exit code (`wait()`).
    -   Doesn't consume RAM/CPU, just a PID slot.
    -   *Fix*: Kill the **Parent**, not the Zombie.

### Load Average Explained
Load Avg (1.00) means:
-   **Linux**: Average number of processes in `R` (Running) **OR** `D` (Uninterruptible Sleep).
-   *Note*: High Load + Low CPU = Disk/Network Bottleneck (Processes stuck in `D`).

---

## Memory Management: Virtual vs Physical

Apps think they have contiguous memory starting at `0x0`. This is a lie (Virtual Memory).

### Components
1.  **MMU (Memory Management Unit)**: Hardware chip mapping Virtual Addr -> Physical Addr.
2.  **Page Tables**: The map stored in kernel memory.
3.  **Page Cache**: Free RAM is used to cache disk blocks.
    -   *Observation*: `free -m` usually shows 90% "used". Check "available".
    -   *Drop Caches*: `sysctl -w vm.drop_caches=3` (Don't do this in prod, it causes IO spikes).

### Swap & OOM
-   **Swappiness (0-100)**: How aggressively to move anon pages to disk.
-   **OOM Killer logic**:
    -   Formula: `badness = (memory_used / total_memory) + oom_score_adj`
    -   Kubernetes uses `oom_score_adj`:
        -   BestEffort: +1000 (Die first).
        -   Burstable: +500.
        -   Guaranteed: -998 (Die last).

---

## The Virtual File System (VFS)

"Everything is a file" is implemented via VFS.

### Inodes vs File Descriptors
-   **Inode**: Metadata on disk (Owner, Permission, Block location). Unique per filesystem.
-   **File Descriptor (FD)**: Integer in a process pointing to an Open File Table entry.
    -   `0`: stdin, `1`: stdout, `2`: stderr.
    -   **Leak**: App opens files but forgets `close()`. Hits `ulimit -n`.

### OverlayFS (The Docker Magic)
How do containers start instantly? They don't copy the OS.
-   **LowerDir**: Read-only base image layers (Debian, Nginx libs). Shared across containers.
-   **UpperDir**: Read-write layer specific to the container.
-   **Merged**: The unified view the app sees.
-   **Copy-On-Write (CoW)**: modifying a file in LowerDir copies it to UpperDir first.

---

## Namespaces Implementation

Namespaces wrap global system resources in an abstraction.

### The 7 Namespaces
1.  **PID**: `CLONE_NEWPID`. Process with PID 1 inside, PID 12345 outside.
2.  **NET**: `CLONE_NEWNET`. `eth0` inside, `veth` outside.
3.  **MNT**: `CLONE_NEWNS`. Mount points. `chroot` on steroids.
4.  **UTS**: Hostname.
5.  **IPC**: Inter-process communication (Shared Mem).
6.  **USER**: UID/GID mapping. (Root inside, nobody outside).
7.  **CGROUP**: Cgroup root view.

### Debugging with `nsenter`
If debugging a Scratch container (no shell):
1.  Find Host PID: `docker inspect --format '{{.State.Pid}}' <id>`
2.  Enter namespace: `nsenter -t <PID> -n -p -- netstat -tulpn`
    -   This runs host's implementation of `netstat` comfortably inside the container's network view.

---

## Control Groups (cgroups) v1 vs v2

Cgroups limit resources (CPU, Mem, IO).

### Cgroup v1 (Hierarchy Mess)
-   Separate hierarchy for each resource.
-   `/sys/fs/cgroup/cpu`
-   `/sys/fs/cgroup/memory`
-   Process could belong to different groups in different hierarchies. Hard to manage properly.

### Cgroup v2 (Unified)
-   Single hierarchy. `/sys/fs/cgroup/unified`.
-   Supports **Pressure Stall Information (PSI)**.
    -   `some` vs `full` stall lines.
    -   Critical for modern autoscaling logic.

### CPU Shares vs Quota
-   **Shares (Requests)**: Weighted priority. Only kicks in when Node is full.
    -   Setting: `cpu.shares` (1024 = 1 core).
-   **Quota (Limits)**: Hard wall.
    -   Setting: `cpu.cfs_quota_us` / `cpu.cfs_period_us` (Runtime / Period).
    -   **Throttling**: If you burn your runtime in 10ms, you freeze for 90ms.
    -   *Symptom*: Latency spikes, but low average CPU usage.

---

## eBPF: The Observability Revolution

**Extended Berkeley Packet Filter** is a bytecode Virtual Machine inside the Kernel.

### How it works
1.  **Write C code**: Hook into kernel function `tcp_connect`.
2.  **Compile to BPF bytecode**: Using Clang/LLVM.
3.  **Load into Kernel**: Verifier checks safety (no infinite loops, no crashing kernel).
4.  **JIT Compile**: To native machine code.
5.  **Map**: Key-Value sharing between Kernel Space (Probe) and User Space (Agent).

### Use Cases
-   **Cilium**: Network CNI. Drops packets at XDP (NIC driver level) for DDoS protection at millions of pps.
-   **Pixie**: Captures request bodies without sidecars by reading internal socket buffers.
-   **Falco**: Detects shell execution in containers by hooking `execve` syscall.
