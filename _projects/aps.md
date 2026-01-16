---
layout: page
title: APS
description: Agile Processor Specialization - Open-source hardware-software co-design framework
img:
importance: 2
category: research
github: https://github.com/pku-liang/APS
related_papers:
  - xiao2025aps
  - zou2025aquasenhancingdomainspecialization
  - peng2025clay
---

**APS (Agile Processor Specialization)** is an open-source hardware-software co-design framework for RISC-V instruction extensions (ISAXs). It provides unified interface abstraction, ISAX-specific synthesis, and compiler infrastructure with automatic pattern matching.

```
┌───────────────────────────────────────────────────────────────────┐
│                        APS Framework                               │
├───────────────────────────────────────────────────────────────────┤
│                                                                    │
│   ISAX.cadl + App.c + Config.yml                                   │
│          │                                                         │
│          ▼                                                         │
│   ┌─────────────────────────────────────────────────────────────┐ │
│   │                    APS-Synth                                 │ │
│   │  CADL ──► SIR ──► SSIR ──► Transactional HW ──► RTL         │ │
│   │  (Cross-level ADL)  (Scheduled)    (CMT2/CIRCT)             │ │
│   └─────────────────────────────────────────────────────────────┘ │
│          │                                                         │
│          │ semantics.json                                          │
│          ▼                                                         │
│   ┌─────────────────────────────────────────────────────────────┐ │
│   │                      APSC Compiler                           │ │
│   │  ┌──────────────┐   ┌─────────────────────┐                 │ │
│   │  │ Pattern Match│   │ Bitwidth-Aware      │                 │ │
│   │  │  • Semantic  │   │ Vectorization       │                 │ │
│   │  │  • Profile   │   │ (pack low-bit ops)  │                 │ │
│   │  └──────────────┘   └─────────────────────┘                 │ │
│   └─────────────────────────────────────────────────────────────┘ │
│          │                                                         │
│          ▼                                                         │
│   ┌─────────────────────────────────────────────────────────────┐ │
│   │                   APS-Itfc (Unified Interface)               │ │
│   │         ┌────────────────┬────────────────┐                  │ │
│   │         │   RoCC Itfc    │   CV-X-IF Itfc │                  │ │
│   │         │ (Rocket/BOOM)  │  (CV32E40X)    │                  │ │
│   │         └────────────────┴────────────────┘                  │ │
│   └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
```

## Three Challenges in ISAX Development

| Challenge | Problem | APS Solution |
|-----------|---------|--------------|
| Interface Divergence | RoCC vs CV-X-IF incompatible | **APS-Itfc**: unified transaction-based abstraction |
| ISAX-Specific Synthesis | HLS ignores processor interaction | **APS-Synth**: CADL with memory/register access |
| Compiler Support | Manual intrinsic insertion | **APSC**: automatic pattern matching + vectorization |

## CADL: Cross-level Architecture Description Language

CADL bridges high-level behavior and low-level hardware:

```rust
#[opcode(7'b0001011)]
#[funct7(7'b0000000)]
rtype butterfly(rs1: u5, rs2: u5, rd: u5) {
    let a: u32 = _irf[rs1];      // Read register file
    let b: u32 = _irf[rs2];
    with i: u32 = (32'd0, i_)    // Hardware loop
    do {
        let x: u32 = _mem[i];    // Memory access
        acc = acc + barrett_mul(x, zeta);
    } while (i_ < n);
    _irf[rd] = acc;              // Write back
}
```

**Key features**:
- Direct access to `_irf` (register file) and `_mem` (processor memory)
- Stateful control: hardware loops, pipelines
- Custom component instantiation (CMT2 modules or Verilog blackboxes)
- Compilation-time functions for metaprogramming

## Synthesis Flow

```
CADL ──► SIR ──► SSIR ──► Transactional Hardware ──► RTL
         │       │               │
         │       │               └─► CMT2 + CIRCT
         │       └─► SDC-based scheduling
         └─► Type inference, function interpretation
```

**Dynamic Pipeline Architecture**: Each stage becomes a transaction with fire logic. Loops get entry/exit transactions with iteration counters.

## APSC Compiler

Two-stage pattern matching:
1. **Semantic-based**: Parse SIR to construct LLVM pattern matchers for instruction sequences
2. **Profile-guided**: For complex control flow (nested loops), compare input-output behavior against ISAX semantics

**Bitwidth-Aware Vectorization**: Pack multiple low-bitwidth operations into one ISAX call:
```c
// Before: 4 separate 8-bit×2-bit dot products
for (int i = 0; i < 8; i++)
    out += DotprodW2A8(activate[i], weight[i]);

// After: Vectorized with bit packing
for (int i = 0; i < 8; i += 4)
    out += DotprodW2A8x4(pack_rs1(activate[i:i+3]),
                         pack_rs2(weight[i:i+3]));
```

## Results

Case studies with **fewer than 175 SLOC** in CADL each:

| Domain | ISAX | Croc Speedup | Rocket Speedup |
|--------|------|--------------|----------------|
| **Post-Quantum Crypto** | Butterflyx2 (NTT) | 6.24× | 10.16× |
| | Karatsuba (PWM) | 10.16× | 14.99× |
| **ML (BitNet b1.58)** | dotprodW2A8x4 | 2.03× | 2.29× |
| **DSP (DPLL)** | IIR filter | 5.51× | 6.03× |

Area overhead: 1-20% depending on platform and ISAX complexity.

## Supported Platforms

- **Chipyard/Rocket**: 5-stage in-order core with RoCC interface
- **PULP/Croc**: CV32E40X 4-stage in-order core with CV-X-IF interface

APS-Itfc adapter: ~425 SLOC for RoCC, ~763 SLOC for CV-X-IF.

## Links

- [Project Website](https://aps.ericlyun.me) with tutorials and documentation
- [GitHub](https://github.com/pku-liang/APS)
