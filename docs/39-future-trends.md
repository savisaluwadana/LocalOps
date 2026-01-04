# Future Trends: LLMOps, Wasm, & GreenOps

## Table of Contents
1.  [LLMOps (Large Language DevOps)](#llmops-large-language-devops)
2.  [WebAssembly (Wasm) on Server](#webassembly-wasm-on-server)
3.  [GreenOps (Sustainability)](#greenops-sustainability)
4.  [Platform as a Service 2.0](#platform-as-a-service-20)

---

## LLMOps (Large Language DevOps)

Deploying Python apps is easy. Deploying 70B parameter models is hard.

### Key Challenges
1.  **GPU Scheduling**: Kubernetes needs NVIDIA device plugins. Bin-packing GPUs is expensive.
2.  **Model Registry**: Git for Code, but what for 100GB weights? (HuggingFace / MLflow).
3.  **Vector Databases**: Pinecone, Milvus, Weaviate. Storing embeddings.
4.  **Evaluation (EvalOps)**: How do you unit test a prompt? (LLM-as-a-Judge).

### The Stack
-   **LangChain / LlamaIndex**: Orchestration.
-   **Ray / KubeRay**: Distributed computing for inference.
-   **vLLM**: High-performance inference engine.

---

## WebAssembly (Wasm) on Server

"Write once, run anywhere" (Actually true this time).

### Docker vs Wasm
-   **Docker**: Virtualizes the OS (userspace). Heavy (MBs/GBs). Cold start ~seconds.
-   **Wasm**: Virtualizes the CPU (Instruction set). Light (KBs). Cold start ~microseconds.

### Use Cases
-   **Edge Computing**: Cloudflare Workers.
-   **Serverless**: Instant scaling to zero.
-   **Plugin Systems**: Running untrusted code safely (e.g., Envoy Filters are Wasm).

### Tools
-   **Fermyon Spin**: Framework for building Wasm microservices.
-   **WasmEdge / Wasmtime**: Runtimes.

---

## GreenOps (Sustainability)

The cloud emits more carbon than the airline industry.

### Measurements
-   **SCI (Software Carbon Intensity)**: Rate of carbon emissions per unit of work.
-   `Carbon = (Energy * Intensity) + Embodied`

### Tactics
1.  **Carbon-Aware Scheduling**: Run batch jobs when the grid is green (Solar/Wind is high). (e.g., KEDA Carbon Aware Scaler).
2.  **Rightsizing**: Turning off unused resources (FinOps = GreenOps).
3.  **ARM Processors**: AWS Graviton / Azure Ampere. 40% better performance/watt.

---

## Platform as a Service 2.0

We are swinging back from "Do everything in K8s YAML" to "Just give me a Heroku experience".

-   **Acorn / Rio**: Higher level abstractions on K8s.
-   **Vercel / Netlify**: The standard for frontend/edge.
-   **Backstage**: The unification UI.
