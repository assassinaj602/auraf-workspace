# Formal Measurement Protocol & Mathematical Formulation

**Project**: AURAF (Adaptive Unified Runtime Architecture for Flutter)  
**Author / Lead**: Muhammad Assad Ullah (`23-CS-78`)  
**Reviewer**: Muhammad Hammas Rasheed (`23-CS-98`)  
**Supervisor**: Dr. Rao Wakeel Ahmad  

---

## 1. Objectives & Empirical Scope

This protocol establishes the scientific measurement standard for evaluating the AURAF runtime engine against static baselines (pure cloud execution vs. pure on-device execution). It provides:
1. Mathematical definitions of all performance, resource, quality, and overhead metrics.
2. The $4 \times 3$ experimental evaluation matrix with strict thermal cool-down bounds.
3. Dataset trace partitioning methodology (50% profiling, 20% validation, 30% test).
4. The formal Lyapunov Drift-plus-Penalty optimization formulation and virtual queue update dynamics ($Q_e$ and $Q_q$).

---

## 2. Metric Formulations & Mathematical Definitions

### A. Responsiveness Metrics

1. **Time To First Token ($\text{TTFT}$)**:
   The elapsed duration from the exact moment an inference request is dispatched until the first decoded output token is received by the Flutter application layer:
   $$\text{TTFT} = t_{\text{first\_token}} - t_{\text{dispatch}} \quad [\text{ms}]$$

2. **Total End-to-End Latency ($T_{\text{total}}$)**:
   The total turnaround time from request issuance to receipt of the end-of-sequence ($\text{EOS}$) token:
   $$T_{\text{total}} = t_{\text{eos}} - t_{\text{dispatch}} \quad [\text{ms}]$$

3. **Decoding Throughput ($\mathcal{T}_{\text{decode}}$)**:
   The rate of output generation after the first token:
   $$\mathcal{T}_{\text{decode}} = \frac{N_{\text{tokens}} - 1}{t_{\text{eos}} - t_{\text{first\_token}}} \quad [\text{tokens/sec}]$$
   where $N_{\text{tokens}}$ is the total number of generated completion tokens.

---

### B. Resource & Cost Metrics

1. **Incremental Energy Consumption ($E_{\text{run}}$)**:
   Measured in milliampere-hours ($\text{mAh}$) using Android's `BatteryManager` current integration over the active execution window $[t_{\text{start}}, t_{\text{end}}]$:
   $$E_{\text{run}} = \frac{1}{3600 \times 1000} \int_{t_{\text{start}}}^{t_{\text{end}}} |I_{\text{batt}}(t)| \, dt \quad [\text{mAh}]$$
   where $I_{\text{batt}}(t)$ is the instantaneous discharge current in $\text{mA}$ sampled at $\ge 10\,\text{Hz}$.

2. **Peak Memory Footprint ($M_{\text{peak}}$)**:
   The maximum resident set size ($\text{RSS}$) allocated by the process during the inference lifecycle:
   $$M_{\text{peak}} = \max_{t \in [t_{\text{start}}, t_{\text{end}}]} \text{RAM}_{\text{resident}}(t) \quad [\text{MB}]$$

3. **Thermal Delta ($\Delta \Theta$)**:
   The temperature delta observed between pre-run baseline and post-run completion:
   $$\Delta \Theta = \Theta_{\text{peak}} - \Theta_{\text{baseline}} \quad [^\circ\text{C}]$$

4. **Monetary Execution Cost ($C_{\text{api}}$)**:
   Direct financial expenditure incurred for remote LLM API calls:
   $$C_{\text{api}} = \sum \left( P_{\text{in}} \cdot \frac{N_{\text{prompt}}}{10^6} + P_{\text{out}} \cdot \frac{N_{\text{completion}}}{10^6} \right) \quad [\$ \text{USD}]$$
   For on-device SLM execution via `edge_forge`, $C_{\text{api}} = 0.0$.

---

### C. Quality & Constraint Metrics

1. **Quality Score ($S_{\text{quality}}$)**:
   Normalized task fidelity score relative to unpruned cloud baseline:
   $$S_{\text{quality}} \in [0.0, 1.0]$$
   Evaluated via semantic similarity (e.g., embedding cosine similarity or task-specific ROUGE-1 / BLEU scores against the ground-truth completion).

2. **Constraint Violation Indicator ($\mathbb{I}_{\text{violated}}$)**:
   Binary flag indicating whether any predefined operational boundaries were breached:
   $$\mathbb{I}_{\text{violated}} = \mathbb{I} \Big( T_{\text{total}} > T_{\text{SLA}} \;\lor\; E_{\text{run}} > E_{\text{max}} \;\lor\; \Theta_{\text{peak}} > \Theta_{\text{crit}} \Big) \in \{0, 1\}$$

---

### D. System Telemetry Overhead Target ($<10\%$)

To ensure that the `StateCollector` and `SQLite` logging modules do not skew empirical results, telemetry overhead must satisfy:
$$\text{Overhead}_{\text{CPU}} = \frac{\text{CPU}_{\text{collector}}}{\text{CPU}_{\text{total}}} < 0.10 \quad (10\%)$$
$$\text{Overhead}_{\text{RAM}} = \frac{\text{RAM}_{\text{collector}}}{\text{RAM}_{\text{app}}} < 0.10 \quad (10\%)$$
Overhead is verified by benchmarking an inference pass with telemetry active versus telemetry disabled.

---

## 3. Experimental Evaluation Matrix

The benchmark harness iterates across a full factorial grid of network conditions and context window sizes:

$$\mathcal{M} = 4 \text{ Network Conditions} \times 3 \text{ Context Budgets} \times 5 \text{ Repetitions} = 60 \text{ Iterations per Model / Placement}$$

| Dimension | Levels / Conditions | Operational Description |
| :--- | :--- | :--- |
| **Network Condition** | 1. `stable` | Wi-Fi / 5G, RTT $< 50\,\text{ms}$, 0% packet loss. |
| | 2. `high_latency` | Simulated RTT $200 - 500\,\text{ms}$, 0% packet loss. |
| | 3. `intermittent` | Fluctuating latency ($100 - 800\,\text{ms}$), 10% packet drop. |
| | 4. `offline` | Local device only, 0 kbps connectivity. |
| **Context Window Size**| 1. `0.5k` (512 tokens) | Short interaction / single turn prompt. |
| | 2. `2k` (2,048 tokens) | Standard document / multi-turn conversation. |
| | 3. `8k` (8,192 tokens) | Long-context retrieval / extensive document context. |
| **Statistical Repetitions** | 5 runs per condition | To report mean $\mu$, sample standard deviation $\sigma$, and 95% confidence intervals. |

### Thermal Cool-Down Protocol
To prevent cumulative thermal throttling from biasing sequential benchmark runs:
1. Device baseline temperature is polled before each repetition.
2. If $\Theta_{\text{device}} > 35.0\,^\circ\text{C}$, the runner enforces an idle cool-down sleep period (e.g. 30 to 60 seconds) until temperature returns below threshold.
3. Ambient room temperature must be maintained at $22 \pm 2\,^\circ\text{C}$.

---

## 4. Dataset Trace Partitioning

Workload traces are sampled from standard benchmark datasets (e.g., MT-Bench, GSM8K, and LongBench) and partitioned into three disjoint splits:

```text
+-------------------------------------------------------------------------------+
|                        Total Benchmark Trace Corpus                           |
+------------------------------------+-------------------+----------------------+
|       50% Profiling Trace          |  20% Validation   |       30% Test       |
|  (Offline characterization &       |  (Hyperparameter  |   (Zero-knowledge    |
|   polynomial fitting)              |   tuning of V)    |    final evaluation) |
+------------------------------------+-------------------+----------------------+
```

1. **50% Profiling Trace**:
   * Used to construct empirical energy-per-token curves, latency distributions, and parameterize initial lookup tables.
2. **20% Validation Trace**:
   * Used to tune the Lyapunov trade-off parameter $V$ and calibrate the target energy/quality queue thresholds ($E_{\text{target}}, Q_{\text{target}}$).
3. **30% Test Trace**:
   * Evaluated strictly out-of-sample during the final benchmark run for reporting official results in the FYP thesis.

---

## 5. Lyapunov Optimization Formulation & Virtual Queues

AURAF formalizes runtime inference routing as a constrained stochastic optimization problem solved via **Lyapunov Drift-plus-Penalty**.

### System State & Queue Vector
Let $t \in \{1, 2, \dots\}$ denote the discrete inference request index. We define two virtual deficit queues to enforce long-term time-average constraints:

1. **Virtual Energy Deficit Queue ($Q_e$)**:
   Guarantees that long-term average energy consumption per request does not exceed energy target $E_{\text{target}}$:
   $$Q_e(t+1) = \max \Big[ Q_e(t) + E(t) - E_{\text{target}}, \; 0 \Big]$$

2. **Virtual Quality Deficit Queue ($Q_q$)**:
   Guarantees that average output quality satisfies minimum threshold $Q_{\text{target}}$:
   $$Q_q(t+1) = \max \Big[ Q_q(t) + Q_{\text{target}} - Q(t), \; 0 \Big]$$

Let $\mathbf{\Theta}(t) \triangleq \big( Q_e(t), Q_q(t) \big)$ denote the combined queue state vector.

### Lyapunov Function & Drift
Define the quadratic Lyapunov function measuring total queue backlog (system instability):
$$L(\mathbf{\Theta}(t)) \triangleq \frac{1}{2} \Big( Q_e(t)^2 + Q_q(t)^2 \Big)$$

The one-step conditional Lyapunov drift is:
$$\Delta(\mathbf{\Theta}(t)) \triangleq \mathbb{E} \Big[ L(\mathbf{\Theta}(t+1)) - L(\mathbf{\Theta}(t)) \;\Big|\; \mathbf{\Theta}(t) \Big]$$

### Drift-plus-Penalty Objective
To balance constraint satisfaction with instantaneous cost/latency minimization, the optimizer minimizes the upper bound of the drift-plus-penalty expression at each request $t$:

$$\min_{a(t) \in \mathcal{A}(t)} \quad \Delta(\mathbf{\Theta}(t)) + V \cdot \mathbb{E}\Big[ \text{Cost}(t, a(t)) \;\Big|\; \mathbf{\Theta}(t) \Big]$$

Expanding the bound yields the per-request decision rule evaluated by `auraf`:

$$a^*(t) = \arg\min_{a \in \mathcal{A}} \Bigg\{ Q_e(t) \cdot E(t, a) - Q_q(t) \cdot Q(t, a) + V \cdot \Big( \alpha \cdot \text{Cost}_{\text{api}}(a) + (1-\alpha) \cdot T_{\text{total}}(a) \Big) \Bigg\}$$

* **$V > 0$**: Control trade-off parameter. Higher $V$ prioritizes cost and latency minimization; lower $V$ prioritizes strict battery and quality queue bounds.
* **$\alpha \in [0, 1]$**: Weighting factor between monetary API cost and user turnaround latency.
* **$a^*(t)$**: The selected `CandidateAction` (placement, context budget, model, and thread count).

---

## 6. M2 Protocol Sign-off

| Role | Name | Signature / Status | Date |
| :--- | :--- | :--- | :--- |
| **Protocol Author** | Muhammad Assad Ullah | Completed M2 Specification | 2026-10-25 |
| **Harness Implementer** | Muhammad Hammas Rasheed | Contract Acknowledged | 2026-10-25 |
| **Project Supervisor** | Dr. Rao Wakeel Ahmad | Pending M2 Review | -- |
