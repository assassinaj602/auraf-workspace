# Milestone 2 (M2) Team Workflow & Collaboration Guide

**Project**: AURAF (Adaptive Unified Runtime Architecture for Flutter)  
**Supervisor**: Dr. Rao Wakeel Ahmad  
**Team Members**:
- Muhammad Hammas Rasheed (Roll No: `23-CS-98`)
- Muhammad Assad Ullah (Roll No: `23-CS-78`)

---

## 1. Executive Summary

Milestone 2 requires building the empirical benchmarking harness, the runtime state telemetry collector, and the formal measurement protocol. To ensure that both team members can work on separate laptops simultaneously without blocking each other or suffering merge conflicts, this guide establishes:
1. Clear domain boundaries and strict folder ownership.
2. A single source of truth for all data structures via [docs/SHARED_DATA_CONTRACT.md](SHARED_DATA_CONTRACT.md).
3. A streamlined Git workflow with branch isolation.
4. A unified demonstration checklist for Dr. Rao Wakeel Ahmad.

---

## 2. Milestone 2 Task Breakdown (Proposal Table 12.1)

### A. Muhammad Hammas Rasheed (23-CS-98)
* **Branch**: `feat/hammas-collector-and-harness`
* **Status**: **Can start immediately** (does not need to wait for Assad).
* **Assigned Deliverables**:
  1. **Task 1 — State Collector & SQLite Telemetry Engine**:
     * Build the background `StateCollector` service to sample device vitals (battery %, discharge current in $mA$, CPU temperature, available RAM, and network status).
     * Implement the local SQLite database client and table definitions to log telemetry entries asynchronously without blocking the UI/event loop.
     * *Location*: `packages/auraf/lib/src/collector/` and `packages/auraf/lib/src/logging/`.
  2. **Task 2 — Automated Benchmark Harness**:
     * Build the Flutter test-bed application that triggers inference scenarios across the experimental conditions.
     * Configure the `integration_test` runner executing automated benchmarks.
     * *Location*: `benchmark_harness/`.
  3. **Task 3 — One-Command Terminal Execution & CSV Export**:
     * Write an automated script (e.g. `scripts/run_m2_benchmark.sh`) that launches the harness on a connected physical Android device, monitors execution, extracts the SQLite records, and writes the validated data directly to `results/m2_benchmark_results.csv`.
     * *Location*: `scripts/` and `results/`.

### B. Muhammad Assad Ullah (23-CS-78)
* **Branch**: `feat/assad-protocol-and-models`
* **Status**: **Can start independently and asynchronously**.
* **Assigned Deliverables**:
  1. **Task 1 — Formal Measurement Protocol & Mathematical Specifications**:
     * Complete [docs/MEASUREMENT_PROTOCOL_OUTLINE.md](MEASUREMENT_PROTOCOL_OUTLINE.md) with rigorous definitions of Time To First Token (TTFT), tokens/sec, average energy draw ($mAh$), thermal cool-down bounds, and Lyapunov virtual queues ($Q_e, Q_q$).
     * Define the prompt trace sampling protocol across 50% profiling, 20% validation, and 30% test splits.
     * *Location*: `docs/MEASUREMENT_PROTOCOL_OUTLINE.md`.
  2. **Task 2 — Core State & Action Models & Lyapunov Scoring Logic**:
     * Implement the core Dart data structures (`DeviceState`, `CandidateAction`, `BenchmarkRecord`, `VirtualQueueState`) matching the agreed schemas in [docs/SHARED_DATA_CONTRACT.md](SHARED_DATA_CONTRACT.md).
     * Implement the Lyapunov Drift-plus-Penalty scoring and queue update mathematical routines.
     * *Location*: `packages/auraf/lib/src/models/`.
  3. **Task 3 — Android Platform Telemetry Hooks & Benchmark Validation**:
     * Assist with low-level Android native telemetry methods (e.g., `BatteryManager`, `HardwarePropertiesManager`, `/sys/class/power_supply`) via Flutter Platform Channels.
     * Validate the statistical integrity of exported CSV data (outlier rejection, thermal sanity checks).
     * *Location*: Native Android bridge inside `packages/auraf/` and validation review in `docs/`.

---

## 3. How Hammas Can Start Immediately Without Waiting for Assad

A common bottleneck in paired development is one developer waiting for the other to finish data models before writing the collection and logging code. 

**This bottleneck is eliminated by the contract**:
1. **Contract First**: [docs/SHARED_DATA_CONTRACT.md](SHARED_DATA_CONTRACT.md) defines every field name, data type, SQLite column name, and CSV header.
2. **Hammas's Independent Track**:
   * Hammas can immediately create the SQLite database using the exact column names specified in Section 3 of the contract (`run_id`, `timestamp`, `device_model`, `battery_current_ma`, etc.).
   * Hammas can write the CSV exporter using the exact header string provided in the contract.
   * Hammas can write the `StateCollector` returning map-based telemetry or temporary DTOs based on the contract fields.
3. **Seamless Merge**:
   * When Assad finishes `packages/auraf/lib/src/models/`, Assad's models will expose `toMap()`, `fromMap()`, `toSqliteRow()`, and `toCsvRow()` that match the contract 1:1.
   * When the two branches are merged into `main`, Hammas's collector and SQLite logger plug directly into Assad's models with zero renaming.

---

## 4. Strict Folder Ownership (Zero Merge Conflict Policy)

To guarantee that git merges are 100% clean, neither developer should modify files owned by the other developer.

| Directory / File Path | Exclusive Owner | Co-Worker Access |
| :--- | :--- | :--- |
| `packages/auraf/lib/src/collector/` | **Hammas** | Read-only |
| `packages/auraf/lib/src/logging/` | **Hammas** | Read-only |
| `benchmark_harness/` | **Hammas** | Read-only |
| `scripts/` | **Hammas** | Review only |
| `results/` | **Hammas** (runtime output) | Read-only |
| `packages/auraf/lib/src/models/` | **Assad** | Read-only |
| `docs/MEASUREMENT_PROTOCOL_OUTLINE.md` | **Assad** | Review only |
| `docs/SHARED_DATA_CONTRACT.md` | **Assad & Hammas (Shared)** | Requires verbal agreement before edit |
| `README.md` & `docs/MILESTONE_2_WORKFLOW.md` | **Assad & Hammas (Shared)** | Main branch updates only |

---

## 5. Step-by-Step Git Commands

### Step 1: Initial Setup on Both Laptops

Both Assad and Hammas should clone the repository from your shared GitHub remote (replace `<REMOTE_URL>` with your actual repository URL):

```bash
# Clone the repository
git clone <REMOTE_URL> auraf-workspace
cd auraf-workspace

# Verify main branch and status
git checkout main
git pull origin main
```

---

### Step 2: Hammas's Daily Workflow

```bash
# 1. Switch to your feature branch (create if first time)
git checkout -b feat/hammas-collector-and-harness

# 2. Work inside your assigned folders:
#    packages/auraf/lib/src/collector/
#    packages/auraf/lib/src/logging/
#    benchmark_harness/
#    scripts/

# 3. Stage and commit only your changes
git add packages/auraf/lib/src/collector/
git add packages/auraf/lib/src/logging/
git add benchmark_harness/
git add scripts/
git commit -m "feat(collector): implement battery and memory telemetry collection"

# 4. Push your branch to GitHub
git push -u origin feat/hammas-collector-and-harness
```

---

### Step 3: Assad's Daily Workflow

```bash
# 1. Switch to your feature branch (create if first time)
git checkout -b feat/assad-protocol-and-models

# 2. Work inside your assigned folders:
#    packages/auraf/lib/src/models/
#    docs/MEASUREMENT_PROTOCOL_OUTLINE.md

# 3. Stage and commit only your changes
git add packages/auraf/lib/src/models/
git add docs/MEASUREMENT_PROTOCOL_OUTLINE.md
git commit -m "docs(protocol): define TTFT, energy averaging, and Lyapunov virtual queues"

# 4. Push your branch to GitHub
git push -u origin feat/assad-protocol-and-models
```

---

### Step 4: Syncing with Main & Pull Request Integration

Before creating a Pull Request to merge into `main`:

```bash
# 1. Commit or stash all local work
git status

# 2. Fetch the latest updates from remote
git fetch origin

# 3. Rebase your feature branch on top of origin/main to keep history linear
git rebase origin/main

# 4. Push updated branch to remote
git push origin <your-branch-name> --force-with-lease
```

* Open a **Pull Request (PR)** on GitHub targeting `main`.
* Tag the other team member as a reviewer.
* Once approved, perform a **Squash and Merge** or **Rebase and Merge**.

---

## 6. Unified Supervisor Demo Checklist (Dr. Rao Wakeel Ahmad)

For the Milestone 2 demonstration, both members present together using **one laptop** connected to **one physical Android test phone**:

### Pre-Demo Verification Checklist:
- [ ] Both `feat/hammas-collector-and-harness` and `feat/assad-protocol-and-models` are merged into `main`.
- [ ] `git status` on the demo laptop is clean on branch `main` with `git pull origin main` executed.
- [ ] Android phone is in Developer Mode with USB Debugging enabled.
- [ ] Verify `adb devices` shows the target device authorized.
- [ ] Phone battery is charged above 80% to ensure linear discharge characteristics.

### Live Demo Execution Flow:

1. **Step 1: Explain Architecture & Protocol (Assad)**
   * Open `docs/MEASUREMENT_PROTOCOL_OUTLINE.md` and `docs/SHARED_DATA_CONTRACT.md`.
   * Walk Dr. Rao Wakeel Ahmad through the mathematical formulation of TTFT, energy measurement ($mAh$), and the Lyapunov drift-plus-penalty queue definitions ($Q_e, Q_q$).
   * Present the $4 \times 3$ experimental matrix and explain the thermal cool-down protocol.

2. **Step 2: Trigger Automated Benchmark (Hammas)**
   * Open terminal and execute the single automated runner script:
     ```bash
     ./scripts/run_m2_benchmark.sh
     ```
   * Show the Flutter harness launching automatically on the Android phone.
   * Point out the real-time telemetry streaming: battery current ($mA$), device temperature ($^\circ C$), and RAM usage.

3. **Step 3: Inspect Telemetry & SQLite Storage (Assad & Hammas)**
   * Show SQLite database file generated locally on the device or pulled via ADB:
     ```bash
     adb shell "run-as com.auraf.benchmark cat databases/auraf_telemetry.db" > results/telemetry.db
     ```
   * Query the SQLite records showing the exact schema defined in `SHARED_DATA_CONTRACT.md`.

4. **Step 4: Verify CSV Export & Data Integrity (Assad & Hammas)**
   * Open `results/m2_benchmark_results.csv`.
   * Verify all 15 columns are properly populated:
     `run_id, timestamp, device_model, network_condition, context_budget, placement, ttft_ms, total_latency_ms, tokens_per_sec, energy_mah, peak_memory_mb, temp_celsius, cost_usd, quality_score, constraint_violated`
   * Confirm that system collector overhead remains strictly under 10% CPU/memory usage.
