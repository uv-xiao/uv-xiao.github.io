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

I am a Ph.D. candidate at the School of Integrated Circuits, Peking University, advised by Prof. [Yun Liang](https://ericlyun.me). I received my Bachelor of Science in EECS from Peking University in 2022. My research is broadly about compiler-centered hardware-software co-design for MLSys, computer architecture, and EDA: how software workloads can guide architectural customization, how those customized capabilities can be synthesized into hardware, and how compiler and system layers can make the result usable by real applications.

One thread of my work studies **hardware synthesis** as the implementation layer of this stack. I build EDA software abstractions that connect high-level design intent with efficient RTL-level hardware. This includes the high-level synthesis framework [Hector](https://github.com/pku-liang/Hector) (ICCAD 2022), the Rust-based hardware description language [Cement](https://github.com/pku-liang/Cement) (FPGA 2024), and more recent work on e-graph-based synthesis optimization in SkyEgg. Across these projects, I have used MLIR, Rust, and compiler IR design to make hardware synthesis more programmable, analyzable, and optimizable.

A second thread focuses on **architecture customization**. I explored how compiler analysis, application profiling, design space exploration, and formal methods can automate the discovery of useful accelerators and custom instructions. [Cayman](https://doi.org/10.1109/DAC63849.2025.11132875) (DAC 2025) generates domain-specific accelerators while considering control flow and data access strategies. [ISAMORE](https://doi.org/10.1145/3779212.3790162) (ASPLOS 2026) uses e-graph anti-unification to find reusable custom instructions from equivalent program fragments.

These two threads motivated a larger goal: a fully integrated co-design toolchain that can derive architecture design, hardware implementation, and compiler support from agile specifications or even directly from target applications. I initiated and led the [APS project](https://aps.ericlyun.me) with lab classmates toward this goal. One long-term example is generating an optimized ML ASIC solution with full ML compiler support from target ML models, with as little manual intervention as possible. I also help organize tutorials at major EDA and architecture conferences to share our work on agile hardware specialization and co-design methodologies; see the [APS tutorials](https://aps.ericlyun.me/tutorials/).

More recently, I have been extending this agenda into **LLM-era compiler and system techniques**. On one side, I study LLMs and agents as new interfaces for compiler optimization and hardware-software co-design, including [EggMind](https://arxiv.org/abs/2604.17364) for LLM-guided equality-saturation strategy synthesis and agentic co-design workflows such as the next-generation APS and Spine. On the other side, I work on compiler and runtime systems for emerging ML workloads, including [IntelliC](https://github.com/uv-xiao/IntelliC), a human- and LLM-friendly infrastructure for retargetable tensor compilation and superoptimization across NVIDIA, Qualcomm Hexagon, and Huawei Ascend architectures; distributed tensor compilation and runtime work such as [PTO Runtime](https://github.com/hw-native-sys/simpler); and [Hive](https://arxiv.org/abs/2604.17353), an inference infrastructure for multi-agent systems with programming-surface and control-layer support.
