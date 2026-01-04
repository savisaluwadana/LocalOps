# Automation Scripting: Python and Go

## Table of Contents

1. [Beyond Bash](#beyond-bash)
2. [Python for DevOps](#python-for-devops)
3. [Go for DevOps](#go-for-devops)
4. [Choosing the Right Tool](#choosing-the-right-tool)
5. [Examples](#examples)

---

## Beyond Bash

Bash is excellent for gluing commands together and file manipulation. However, as complexity grows, Bash becomes difficult to read, test, and maintain.

**When to switch from Bash:**
- Complex string manipulation or regex.
- Interacting with APIs (REST/GraphQL).
- Parsing JSON/YAML (handling arrays/objects).
- Cross-platform compatibility (Windows/Linux).
- Need for robust error handling (try/catch).

---

## Python for DevOps

**Strengths:** Rich ecosystem, readable, standard for AI/ML and DataOps.

### Key Libraries

-   **`os` / `sys` / `subprocess`**: System interaction.
-   **`argparse` / `click` / `typer`**: CLI creation.
-   **`requests`**: HTTP Client (The API standard).
-   **`boto3`**: AWS SDK.
-   **`pyyaml` / `json`**: Configuration parsing.
-   **`pandas`**: Data analysis (Log analysis).
-   **`fabric` / `ansible`**: Remote execution.

### Example: Check Website Health (Python)

```python
import requests
import sys

def check_site(url):
    try:
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            print(f"✅ {url} is UP")
        else:
            print(f"⚠️ {url} returned {response.status_code}")
            sys.exit(1)
    except requests.exceptions.RequestException as e:
        print(f"❌ {url} is DOWN: {e}")
        sys.exit(1)

if __name__ == "__main__":
    check_site("https://google.com")
```

---

## Go for DevOps

**Strengths:** Single binary (easy distribution), static typing, concurrency, performance. Kubernetes and Docker are written in Go.

### Use Cases

-   **Kubernetes Controllers/Operators**: Standard language using client-go.
-   **CLI Tools**: Fast, no runtime dependency (compiles to binary).
-   **High Performance Agents**: Log shippers, sidecars.
-   **Terraform Providers**: Custom resource management.

### Key Libraries

-   **`os` / `exec`**: System interaction.
-   **`net/http`**: Robust standard library for HTTP.
-   **`flag` / `cobra`**: CLI creation (Cobra is industry standard).
-   **`encoding/json`**: Struct-based parsing.

### Example: Check Website Health (Go)

```go
package main

import (
    "fmt"
    "net/http"
    "os"
    "time"
)

func main() {
    url := "https://google.com"
    client := http.Client{
        Timeout: 5 * time.Second,
    }

    resp, err := client.Get(url)
    if err != nil {
        fmt.Printf("❌ %s is DOWN: %v\n", url, err)
        os.Exit(1)
    }
    defer resp.Body.Close()

    if resp.StatusCode == 200 {
        fmt.Printf("✅ %s is UP\n", url)
    } else {
        fmt.Printf("⚠️ %s returned %d\n", url, resp.StatusCode)
        os.Exit(1)
    }
}
```

---

## Choosing the Right Tool

| Scenario | Recommended | Reason |
|----------|-------------|--------|
| **Simple file ops** (mv, cp, grep) | **Bash** | Native, fastest to write. |
| **Complex Logic** (If, Loops, Data) | **Python** | Readable, great standard lib. |
| **API Interaction** (AWS, REST) | **Python** | `requests` and `boto3` are unbeatable. |
| **Performance Critical** | **Go** | Compiled, concurrency. |
| **Distributing functionality** | **Go** | Single binary > Python venv hell. |
| **Kubernetes Extensions** | **Go** | Native K8s client support. |

---

## Examples

### 1. Boto3: List S3 Buckets (Python)

```python
import boto3

s3 = boto3.client('s3')
response = s3.list_buckets()

print("Existing buckets:")
for bucket in response['Buckets']:
    print(f"  {bucket['Name']}")
```

### 2. Parse JSON Log (Python)

```python
import json

log_line = '{"timestamp": "2024-01-01", "level": "ERROR", "msg": "failed"}'
data = json.loads(log_line)

if data['level'] == 'ERROR':
    print(f"Alert: {data['msg']}")
```

### 3. Concurrent Web Checker (Go)

Go routines make parallel tasks effectively free.

```go
package main

import (
	"fmt"
	"net/http"
	"sync"
)

func check(url string, wg *sync.WaitGroup) {
	defer wg.Done()
	_, err := http.Get(url)
	if err != nil {
		fmt.Printf("%s: DOWN\n", url)
		return
	}
	fmt.Printf("%s: UP\n", url)
}

func main() {
	urls := []string{"https://google.com", "https://github.com", "https://amazon.com"}
	var wg sync.WaitGroup

	for _, u := range urls {
		wg.Add(1)
		go check(u, &wg) // Launch goroutine
	}
	wg.Wait() // Wait for all
}
```
