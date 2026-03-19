---
layout: about
title: About
permalink: /
subtitle:

profile:
  align: right
  image: self_at_fuzhou.jpg
  image_circular: true # crops the image to make it circular
  more_info: >
    <p>Youwei Xiao (肖有为) </p>
    <p>School of Integrated Circuits</p>
    <p>Peking University</p>
    <p>Beijing, China</p>

news: true # includes a list of news items
selected_papers: true # includes a list of papers marked as "selected={true}"
social: true # includes social icons at the bottom of the page
---

I am a Ph.D. candidate at the School of Integrated Circuits, Peking University, advised by Prof. [Yun Liang](https://ericlyun.me). My research focuses on software techniques for MLSys/Architecture/EDA, with emphasis on domain-specific languages (DSLs) and compiler techniques. Before that, I received my Bachelor of Science in EECS at Peking University in 2022.

My research centers on developing EDA software techniques that bridge the gap between high-level architectural specifications and register-transfer-level (RTL) hardware implementations. I have contributed to and led several projects on multi-level intermediate representations and hardware synthesis. Notable contributions include the open-source hardware description language [Cement](https://github.com/pku-liang/Cement) (FPGA 2024) and the high-level synthesis framework [Hector](https://github.com/pku-liang/Hector) (ICCAD 2022). We built these frameworks with the MLIR infrastructure and the Rust programming language. More recently, I've been exploring e-graph techniques for hardware synthesis optimization in the SkyEgg project.

For computer architecture, I explored the automated generation of domain-specific accelerators and custom instructions. I combined application profiling, design space exploration, and dynamic programming to build the Cayman framework (DAC 2025) for automatic accelerator generation with control flow and data access strategies considered. I also proposed reusable instruction customization using e-graph anti-unification techniques, implemented as the [ISAMORE](https://github.com/isamore-group/ISAMORE) framework (ASPLOS 2026).

With my research experiences spanning hardware synthesis and computer architecture, I picked up a goal to create a fully-integrated co-design toolchain - to generate everything (architecture design, hardware implementation, and compiler support) from just ONE agile specification or even only the target applications. For example, one of our ultimate goals is to generate an optimized ML ASIC solution with full ML compiler support given some ML models as acceleration targets, without any human intervention. To achieve this goal, I initiated and led the [APS project](https://aps.ericlyun.me) together with my lab classmates. Actually, we are not far from the dream! I also actively contribute to tutorials at major EDA and architecture conferences, sharing our research on agile hardware specialization and co-design methodologies (see [APS tutorials](https://aps.ericlyun.me/tutorials/)).

Based on my accumulated skills in compilers, DSLs, and architecture, I am actively exploring interesting topics in ML compilers and systems. Currently, I am actively researching or contributing to:

1. [Retargetable tensor compilers](https://github.com/uv-xiao/htp) and superoptimizers, targeting NVIDIA (Ampere, Hopper, Blackwell), QualComm Hexagon, and Huawei Ascend architectures.
2. Distributed tensor compilation and runtime, especially [PTO Runtime](https://github.com/hw-native-sys/simpler).
3. Agentic superoptimizers ([EggMind](https://openreview.net/forum?id=5jY9ryobP7)) with LLM-driven equality saturation.
4. Agentic hardware-software co-design toolchain: the next-generation APS!
5. Inference infrastructure for multi-agent system with programming surface and control layers.
