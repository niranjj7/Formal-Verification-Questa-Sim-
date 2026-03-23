# Formal Verification

---

## Tool Flow Mapping

```
  Spec / Design (Verilog / SystemVerilog)
          │
          ▼
  ┌───────────────────┐
  │  FRONT-END TOOL   │  ──►  Questa Sim / Questa Formal Compiler
  │  (questa formal   │        Commands: vlib, vmap, vlog, formal compile
  │   compile)        │
  └────────┬──────────┘
           │  (builds internal AIG / CNF mathematical model)
           ▼
  ┌───────────────────┐
  │  MATHEMATICAL     │  ──►  AIG (And-Inverter Graph) / CNF formula
  │  MODELS           │        Transition System: (S, S0, T, L)
  └────────┬──────────┘
           │
           ▼
  ┌───────────────────┐
  │  BACK-END         │  ──►  Questa Formal Verification Engine
  │  VERIFICATION     │
  │  ENGINE           │
  │                   │  Reasoning Engine: SAT Solver
  │  (formal verify)  │   • Equivalence: UNSAT on miter → PROVEN
  └───────────────────┘   • BMC: UNSAT for negated property → HOLDS
```

| Flow Stage | Tool Used |
|---|---|
| **Front-end Tool** | Questa Formal (`vlog`, `formal compile`) |
| **Back-end Verification Engine** | Questa Formal (`formal verify`) |
| **Reasoning Engine (Back-end)** | SAT Solver (integrated in Questa Formal) |
| **Mathematical Model** | And-Inverter Graph (AIG) + CNF (Conjunctive Normal Form) |

---

## What is a Mathematical Model?

A **mathematical model** in formal verification is a precise, unambiguous representation of a hardware circuit's behaviour that a reasoning engine can operate on.

### Transition System (from theory)

A circuit is modelled as a **Kripke Structure / Transition System**:

```
M = (S, S₀, T, AP, L)
```

| Symbol | Meaning | Example (2-bit counter) |
|---|---|---|
| **S** | Set of all states | {00, 01, 10, 11} |
| **S₀** | Set of initial states | {00} (after reset) |
| **T ⊆ S × S** | Transition relation | {(00→01), (01→10), (10→11), (11→00)} |
| **AP** | Atomic propositions | {count==00, count==11} |
| **L : S → 2^AP** | Labelling function | L(11) = {count==11} |

### AIG / CNF (what Questa Formal actually builds)

The transition relation `T` is encoded as a **CNF formula** (product of clauses) and solved by the SAT engine. Each wire in the circuit becomes a Boolean variable, and each gate becomes a set of clauses.

---

## Repository Structure

```
formal_verification/
├── README.md                          ← This file
├── q1_equivalence/
│   ├── ref.v                          ← Circuit A (reference)
│   ├── impl.v                         ← Circuit B (implementation)
│   ├── miter.sv                       ← Miter circuit with assertion
│   └── run_equiv.tcl                  ← Questa Formal script
├── q2_safety_bmc/
│   ├── counter_safety.sv              ← Counter + safety assert
│   └── run_bmc_safety.tcl             ← Questa BMC script
├── q3_liveness_bmc/
│   ├── counter_liveness.sv            ← Counter + liveness assert
│   └── run_bmc_liveness.tcl           ← Questa BMC script
└── q4_optimization/
    ├── top.v                          ← Original RTL
    ├── top_opt.v                      ← Optimized netlist
    ├── miter_opt.sv                   ← Miter for opt check
    └── run_opt_equiv.tcl              ← Questa Formal script
```

---

## 1 – Sequential Equivalence Checking

### Circuit Description

| | Circuit A (`ref.v`) | Circuit B (`impl.v`) |
|---|---|---|
| Expression | `y <= a & b` | `y <= ~(~a \| ~b)` |
| Logic | Direct AND | De Morgan's equivalent AND |
| Equivalence? | ✅ Yes — by De Morgan's theorem |

### Theoretical Work

#### Step 1 – Model both circuits as Transition Systems

**Circuit A (ref):**
```
S_A = {0, 1}  (state of register y)
T_A : y_next = a & b
```

**Circuit B (impl):**
```
S_B = {0, 1}
T_B : y_next = ~(~a | ~b)  =  a & b   (by De Morgan)
```

#### Step 2 – Construct the Miter Circuit

A **miter** combines both circuits with shared inputs and XORs their outputs:

```
         ┌──────────┐
a, b ───►│   ref    │──► y_ref ──┐
         └──────────┘            ├─► XOR ──► miter_out
         ┌──────────┐            │    (should always = 0)
a, b ───►│   impl   │──► y_impl ─┘
         └──────────┘
```

`miter_out = y_ref XOR y_impl`

#### Step 3 – SAT-based Sequential Equivalence Check

The SAT solver is asked: **"Does there exist any input sequence such that `miter_out = 1`?"**

```
SAT Formula:  I(s0) ∧ T_miter(s0, s1) ∧ ... ∧ T_miter(s_{k-1}, sk) ∧ (miter_out_k = 1)

M₁ ≡ M₂  iff  this formula is UNSATISFIABLE
```

#### SAT Solver Output Interpretation (Equivalence Check)

| SAT Result | Verification Outcome | Meaning |
|---|---|---|
| **UNSATISFIABLE (UNSAT)** | ✅ **PROVEN** — circuits are equivalent | No input sequence can make outputs differ → `M₁ ≡ M₂` |
| **SATISFIABLE (SAT)** | ❌ **FAILED** — circuits are NOT equivalent | A counterexample input sequence is produced |

### Command Descriptions

| Command | Description |
|---|---|
| `vlib work` | Creates a new ModelSim/Questa library directory named `work` to store compiled design units |
| `vmap work work` | Maps the logical library name `work` to the physical `work` directory |
| `vlog -sv -work work ref.v` | Compiles `ref.v` as SystemVerilog (`-sv`) into the `work` library. Parses, type-checks, and stores elaboration info |
| `vlog -sv -work work impl.v` | Same as above for `impl.v` |
| `vlog -sv -work work miter.sv` | Compiles the miter circuit (contains `assert property`) into the library |
| `formal compile -d miter -work work` | Elaborates the `miter` top-level from `work`, builds the internal AIG (And-Inverter Graph) and CNF representation used by the SAT engine |
| `formal verify -init -effort high` | Runs the Questa Formal SAT-based verification engine at maximum effort, checking all `assert property` statements in the design |
| `report_property -verbose` | Prints a detailed table of all properties with PROVEN / FAILED status and any counterexample traces |

---

## 2 – Property Checking: Safety via BMC

### Property

```
G ¬(count == 2'b11)
"Globally, count never equals 3"
```

### Addition to Verilog for Property Check

Yes — an `assert property` block was added inside the module:

```systemverilog
property safety_no_state_11;
    @(posedge clk) (count !== 2'b11);
endproperty
assert property (safety_no_state_11)
    else $error("SAFETY VIOLATION: counter reached 2'b11");
```

This is the **SVA (SystemVerilog Assertion)** that Questa Formal targets.

### BMC SAT Formula Construction

BMC unrolls the design for `k` steps and asks: *"Can the bad state be reached?"*

```
φ_BMC(k) =  I(s₀)  ∧  T(s₀,s₁) ∧ T(s₁,s₂) ∧ ... ∧ T(s_{k-1},sₖ)  ∧  ¬P(sₖ)
              ↑              ↑ transition relation (counter logic)        ↑ negated property
         initial state                                               (count == 11)
```

For the 2-bit counter, `T(sᵢ, sᵢ₊₁)` encodes:

```
count_next = (rst) ? 0 : count + 1
```

### SAT Output Interpretation (Safety / BMC)

| SAT Result | Verdict | Meaning |
|---|---|---|
| **SATISFIABLE** | ❌ **FAILED** — property VIOLATED | Solver found a path from initial state reaching `count==11`. A counterexample waveform is shown. The counter WILL reach 11 (after 3 clock ticks without reset). |
| **UNSATISFIABLE** | ✅ **HOLDS** up to bound `k` | No path of length ≤ k reaches `count==11`. Does not prove for all depths unless k ≥ diameter. |

> **Note:** For this counter (no constraint on `rst`), the property will **FAIL** — the tool will find a counterexample trace: `rst=0` for 3 cycles takes `count` from `00→01→10→11`.

### Command Descriptions

| Command | Description |
|---|---|
| `vlog -sv -work work counter_safety.sv` | Compiles the counter module with embedded SVA assertions into the library |
| `formal compile -d counter -work work` | Elaborates the `counter` top-level; Questa Formal extracts all `assert property` and `cover property` statements as verification targets |
| `formal verify -bounded -depth 10` | Runs **Bounded Model Checking** — unrolls the transition relation for 10 clock steps and queries the SAT solver for each property. `-bounded` selects BMC mode; `-depth 10` sets the unrolling bound k=10 |
| `report_property -verbose` | Displays result for each property: PROVEN, FAILED (with depth), or UNDETERMINED |

---

## 3 – Property Checking: Liveness via BMC

### Property

```
GF(count == 2'b00)
"Globally, Eventually count returns to 00"
```

### SVA Representation

```systemverilog
property liveness_count_returns_to_00;
    @(posedge clk) strong(##[0:4] (count == 2'b00));
endproperty
assert property (liveness_count_returns_to_00);

cover property (@(posedge clk) count == 2'b00);
```

### BMC for Liveness

For liveness, BMC searches for a **lasso-shaped counterexample** — a finite prefix followed by an infinite loop where `count == 00` never occurs:

```
s₀ → s₁ → ... → sⱼ → sⱼ₊₁ → ... → sₖ → (back to sⱼ)
                               ↑
                    P(sᵢ) = false for all i in loop
```

### SAT Output Interpretation (Liveness)

| SAT Result | Verdict | Meaning |
|---|---|---|
| **SATISFIABLE** | ❌ **FAILED** | Found a loop where count==00 never recurs → liveness violated |
| **UNSATISFIABLE** | ✅ **HOLDS** (up to k) | No such loop exists up to depth k |

> **Expected result:** With free `rst` input, the counter **satisfies** liveness — every 4 cycles it wraps through 00 (or rst can drive it to 00). Tool returns **HOLDS**.

### Command Descriptions

| Command | Description |
|---|---|
| `vlog -sv -work work counter_liveness.sv` | Compiles liveness-annotated counter |
| `formal compile -d counter -work work` | Elaborates design; registers both `assert` and `cover` targets |
| `formal verify -bounded -depth 8` | BMC with depth 8 — sufficient for a 2-bit counter (full cycle = 4 steps). Checks for lasso counterexamples |
| `report_property -verbose` | Shows COVERED (liveness witness found) or FAILED for each target |

---

## 4 – Logic Optimization + Equivalence Check

### Boolean Simplification

```
F = (A & B) | (A & B & C)
  = (A & B)(1 | C)         [factor out A & B]
  = (A & B)(1)             [1 | C = 1]
  = A & B                  [Absorption Law]
```

### Part A – Logic Optimization (Yosys)

| Yosys Command | Description |
|---|---|
| `read_verilog top.v` | Reads RTL source into Yosys internal representation |
| `hierarchy -check` | Checks module hierarchy; resolves module instantiations |
| `proc` | Converts `always` blocks and `initial` blocks into netlist primitives (muxes, flip-flops) |
| `opt` | Runs a suite of Boolean optimisation passes: constant propagation, dead-code elimination, absorption, redundancy removal |
| `techmap` | Maps abstract cells to technology-specific gate primitives |
| `write_verilog top_opt.v` | Writes the optimised gate-level netlist back to Verilog |

### Part B – Equivalence Check (Questa Formal)

| Command | Description |
|---|---|
| `vlog -sv -work work top.v` | Compile original RTL |
| `vlog -sv -work work top_opt.v` | Compile optimized netlist |
| `vlog -sv -work work miter_opt.sv` | Compile combinational miter circuit |
| `formal compile -d miter_opt -work work` | Elaborate miter; build COI (Cone of Influence) model |
| `formal verify -effort high` | For combinational design: SAT exhaustively covers all 2³=8 input combinations (A,B,C). No clock unrolling needed |
| `report_property -verbose` | PROVEN → optimization is safe; FAILED → bug in optimization |

### SAT Output Interpretation (Equivalence after Optimization)

| SAT Result | Verdict | Meaning |
|---|---|---|
| **UNSATISFIABLE (PROVEN)** | ✅ Optimization is correct | No (A,B,C) makes `F_orig ≠ F_opt`. Absorption law verified formally. |
| **SATISFIABLE (FAILED)** | ❌ Optimization introduced a bug | A specific (A,B,C) counterexample is returned where outputs differ |

---

## Summary – SAT Solver Outputs

| Check Type | SAT = SATISFIABLE | SAT = UNSATISFIABLE |
|---|---|---|
| **Equivalence Check** | ❌ Circuits differ — counterexample shown | ✅ Circuits are equivalent (`M₁ ≡ M₂`) |
| **Safety BMC** | ❌ Bad state reachable — violation trace shown | ✅ Property holds up to bound k |
| **Liveness BMC** | ❌ Infinite loop without P found | ✅ No lasso without P up to bound k |
| **Optimization Equiv.** | ❌ Optimization introduced bug | ✅ Optimized netlist is functionally correct |

---

## How to Run

### Prerequisites
- Questa Sim / Questa Formal (Mentor / Siemens EDA)
- (Optional for Q4 optimization) Yosys

### Run Equivalence Check (Q1)
```bash
cd q1_equivalence
vsim -c -do run_equiv.tcl
```

### Run Safety BMC (Q2)
```bash
cd q2_safety_bmc
vsim -c -do run_bmc_safety.tcl
```

### Run Liveness BMC (Q3)
```bash
cd q3_liveness_bmc
vsim -c -do run_bmc_liveness.tcl
```

### Run Optimization + Equivalence (Q4)
```bash
cd q4_optimization
# Optional: run Yosys first to regenerate top_opt.v
# yosys -s optimize.ys
vsim -c -do run_opt_equiv.tcl
```

---

*ECS324 VLSI Testing and Verification | Formal Verification Lab*
