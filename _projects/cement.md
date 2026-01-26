---
layout: page
title: Cement
description: Cycle-deterministic embedded HDL in Rust with event-based control synthesis
img:
importance: 4
category: tools
github: https://github.com/pku-liang/Cement
related_papers:
  - xiao2025cement2temporalhardwaretransactions
  - xiao2025cmt2
  - xiao2024cement
---

**Cement** is a hardware design framework comprising **CmtHDL** (an embedded HDL in Rust) and **CmtC** (a compiler with timing analysis and control synthesis). It enables productive FPGA programming while preserving cycle-deterministic behavior and timing awareness.

```text
+----------------------------------------------------------+
|                    Cement Framework                      |
+----------------------------------------------------------+
|                                                          |
|  CmtHDL (Rust)              CmtC Compiler                |
|  +--------------+          +--------------+              |
|  | RTL Layer    |          |  ir-rs       |              |
|  | (ports,wires)|  ----->  |  (SSA IR)    |              |
|  +--------------+          +--------------+              |
|  | Event Layer  |          |  Timing      |              |
|  | (occurrence) |  ----->  |  Analysis    |              |
|  +--------------+          +--------------+              |
|  | Ctrl Sub-lang|          |  Control     |              |
|  | seq/par/if/  |  ----->  |  Synthesis   |  --> Verilog |
|  | for/while    |          |  (State Tree)|              |
|  +--------------+          +--------------+              |
+----------------------------------------------------------+
```

## The FPGA Programming Gap

| Approach | Microarch Express. | Cycle Determinism | Timing Awareness |
|----------|-------------------|-------------------|------------------|
| Chisel/eHDLs | general | no | no |
| Bluespec | general | no | no |
| HLS (Vitis) | limited by directives | no | yes |
| DSLs | limited | partial | yes |
| **Cement** | **general** | **yes** | **yes** |

Existing approaches force tradeoffs: HDLs lack timing awareness, HLS lacks determinism, DSLs limit expressiveness. Cement achieves all three.

## Event-Based Extension

CmtHDL extends standard RTL with two key innovations:

**Event Layer** - Events guard hardware behavior with timing information:
```rust
let receive = event! {
    resend.i %= arbiter.resend;  // connection
    sel_reg.wr %= arbiter.sel;   // operation
};
```

**Ctrl Sub-Language** - Procedural statements specify deterministic timing:
```rust
let pipeline = stmt! {
    seq { send; wait; receive; xbar; }  // 4 stages, sequential
};
synth!(pipeline, Pipeline::new(clk, go, /*II=*/1));
```

Six statement types: `step`, `seq`, `par`, `if`, `for`, `while` - each with deterministic latency rules.

## CmtC Compiler

- **ir-rs**: Pure-Rust IR framework inspired by MLIR, with SSA operations
- **Timing Analysis**: Static analysis detects violations at elaboration; dynamic monitoring catches data-dependent issues in simulation
- **Control Synthesis**: State tree representation optimizes FSM encoding (balancing LUT vs FF usage)

## Results

On PolyBench benchmarks vs Vitis HLS and Dahlia-Calyx:
- **1.41×-3.49× speedup** with cycle-deterministic scheduling
- **23%-82% resource savings** from optimized control synthesis
- **Comparable LoC** to HLS (0.97× geomean)

Case study on systolic arrays: 51% LUT savings, 13% throughput improvement vs prior work, with 2 person-months development (vs 6 for Chisel-based EMS).

## Links

- [GitHub - Rust version](https://github.com/pku-liang/Cement)
- [GitHub - MLIR/CIRCT version](https://github.com/arch-of-shadow/circt-cmt2)
