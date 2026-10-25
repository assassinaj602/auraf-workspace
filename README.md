# AURAF: Adaptive Unified Runtime Architecture for Flutter

[![Milestone](https://img.shields.io/badge/Milestone-M2%20Telemetry%20%26%20Harness-blue)](docs/MILESTONE_2_WORKFLOW.md)
[![Project](https://img.shields.io/badge/Project-Final%20Year%20Project-success)](#)
[![Supervisor](https://img.shields.io/badge/Supervisor-Dr.%20Rao%20Wakeel%20Ahmad-orange)](#)

---

## 1. Project Overview

**AURAF (Adaptive Unified Runtime Architecture for Flutter)** is a cross-platform runtime engine designed to optimize the execution of generative and hybrid AI workloads on mobile devices. Modern mobile AI applications face severe resource trade-offs between cloud API latency/monetary cost and on-device execution limits (RAM, thermal dissipation, battery capacity). 

AURAF dynamically brokers inference requests using **Lyapunov Drift-plus-Penalty Stochastic Control**, balancing response latency, monetary cost, battery health, and output quality without requiring prior knowledge of future request arrivals.

### Modular Architecture (4 Core Packages)

The workspace is organized into a modular mono-repository consisting of four interconnected packages:

1. **`packages/token_guard`**:
   * Context-budgeting and token-pruning engine.
   * Compresses prompt context dynamically according to network status, memory pressure, and target cost.
2. **`packages/hybrid_brain`**:
   * Dynamic inference router.
   * Decides request placement between cloud LLM providers (e.g., Gemini, Claude, OpenAI) and on-device SLMs (e.g., Gemma 2B, Phi-3, Qwen 2.5 via ONNX/TFLite/ExecuTorch).
3. **`packages/edge_forge`**:
   * On-device model runtime abstraction and acceleration layer.
   * Manages hardware acceleration (NNAPI, GPU, Vulkan, NPU) and thread pool allocation.
4. **`packages/auraf`**:
   * The central orchestration package housing the unified state engine.
   * Implements the **State Collector**, local **SQLite Telemetry Logger**, and the **Lyapunov Optimization Engine** that synthesizes telemetry from all packages to issue optimal runtime decisions.

```text
                               +-----------------------------+
                               |     Flutter Application     |
                               +-----------------------------+
                                              |
                                              v
+-----------------------------------------------------------------------------------------+
|                                    auraf (Core Engine)                                  |
|                                                                                         |
|  +--------------------+         +------------------------+         +-----------------+  |
|  |   StateCollector   | ------> | Lyapunov Drift-Penalty | ------> |  SQLite Logger  |  |
|  | (Battery, RAM, Net)|         |  Optimization Engine   |         | (Telemetry DB)  |  |
|  +--------------------+         +------------------------+         +-----------------+  |
+-----------------------------------------------------------------------------------------+
       |                                      |                                   |
       v                                      v                                   v
+-------------------+              +----------------------+              +----------------+
|    token_guard    |              |     hybrid_brain     |              |   edge_forge   |
| (Context Pruning) |              | (Placement Routing)  |              | (On-Device SLM)|
+-------------------+              +----------------------+              +----------------+
```

---

## 2. Milestone 2 (M2) Goals & Supervisor Demo Requirements

Milestone 2 establishes the empirical baseline, telemetry logging infrastructure, and automated benchmarking harness for AURAF.

### Target Deliverables for Demo with Dr. Rao Wakeel Ahmad:

1. **Formal Measurement Protocol (`docs/MEASUREMENT_PROTOCOL_OUTLINE.md`)**:
   * Rigorous definitions of Time To First Token (TTFT), tokens/sec, battery drain ($mAh$), thermal cool-down thresholds, and Lyapunov virtual queues ($Q_e, Q_q$).
   * A $4 \times 3$ experimental matrix (4 network states $\times$ 3 context sizes: 0.5k, 2k, 8k tokens) evaluated with 5 repetitions per condition.
2. **State Collector Module & SQLite Logging (`packages/auraf/lib/src/`)**:
   * Real-time sampling of battery level, discharge current ($mA$), device temperature ($^\circ C$), available RAM ($MB$), and network condition.
   * High-throughput, non-blocking telemetry persistence into a local SQLite database (`BenchmarkRecord` schema).
3. **One-Command Automated Benchmark Harness (`benchmark_harness/` & `scripts/`)**:
   * An integration-test-driven harness that executes test sequences on a connected physical Android device.
   * Triggerable via a single terminal command that executes the suite, queries the SQLite database, and exports validated results to `results/m2_benchmark_results.csv`.

---

## 3. Team Member Roles & Branching Strategy

| Team Member | Reg ID | Primary Milestone 2 Focus | Working Git Branch |
| :--- | :--- | :--- | :--- |
| **Muhammad Hammas Rasheed** | `23-CS-98` | Telemetry Collector, SQLite Logger, Benchmark Harness UI & Execution Script | `feat/hammas-collector-and-harness` |
| **Muhammad Assad Ullah** | `23-CS-78` | Measurement Protocol, Data Contracts, Core State/Action Models, Lyapunov Equations | `feat/assad-protocol-and-models` |

Both members work on isolated branches with decoupled directories and integrate via Pull Requests against the shared contract.

---

## 4. Documentation Index

Before contributing code, consult the following detailed specifications in the `docs/` directory:

1. **[Milestone 2 Workflow Guide](docs/MILESTONE_2_WORKFLOW.md)**:
   * Step-by-step laptop setup, branch creation, daily Git workflow, zero-conflict directory ownership, and the final demo presentation checklist.
2. **[Shared Data Contract](docs/SHARED_DATA_CONTRACT.md)**:
   * Language-agnostic definitions, Dart field names, data types, SQLite DDL schemas, and CSV column orders governing `DeviceState`, `CandidateAction`, and `BenchmarkRecord`.
3. **[Measurement Protocol Outline](docs/MEASUREMENT_PROTOCOL_OUTLINE.md)**:
   * The scientific methodology, metrics mathematical formulations, dataset split traces (50% profiling, 20% validation, 30% test), cool-down rules, and Lyapunov virtual queue updates.

---

## 5. Repository Directory Layout

```text
fyp-project/
├── README.md                               # Project overview and milestone index
├── .gitignore                              # Dart, Flutter, Android, and artifact ignore rules
├── docs/
│   ├── MILESTONE_2_WORKFLOW.md             # Developer workflow, Git rules, and demo checklist
│   ├── SHARED_DATA_CONTRACT.md             # Schemas for State, Action, SQLite, and CSV
│   └── MEASUREMENT_PROTOCOL_OUTLINE.md     # Protocol, metrics formulas, and test matrices
├── packages/
│   ├── auraf/                              # Central orchestration runtime
│   │   ├── lib/src/models/.gitkeep         # Assad: State, Action, and Queue data models
│   │   ├── lib/src/collector/.gitkeep      # Hammas: Device telemetry collector
│   │   └── lib/src/logging/.gitkeep        # Hammas: SQLite telemetry database logger
│   ├── token_guard/.gitkeep                # Future M3: Context budgeting & token pruning
│   ├── hybrid_brain/.gitkeep               # Future M3: Cloud vs Edge routing
│   └── edge_forge/.gitkeep                 # Future M3: On-device SLM execution runtime
├── benchmark_harness/                      # Hammas: Flutter app running integration benchmarks
│   └── .gitkeep
├── scripts/                                # Hammas: Automated one-command runner scripts
│   └── .gitkeep
└── results/                                # Output directory for m2_benchmark_results.csv
    └── .gitkeep
```
