---
layout: about
title: About
permalink: /
subtitle:
lang: en
nav: false
language_switch:
  - label: English
    url: /
    active: true
  - label: 中文
    url: /zh/

profile:
  align: right
  image: self_at_fuzhou.jpg
  image_circular: true # crops the image to make it circular
  more_info: >
    <p><span class="profile-name-en">Youwei Xiao</span> <span class="profile-name-zh">肖有为</span></p>
    <p>School of Integrated Circuits</p>
    <p>Peking University</p>
    <p>Beijing, China</p>

news: true # includes a list of news items
selected_papers: true # includes a list of papers marked as "selected={true}"
social: true # includes social icons at the bottom of the page
---

I am a Ph.D. candidate at the School of Integrated Circuits, Peking University, advised by Prof. [Yun Liang](https://ericlyun.me), and a Large Language Model Algorithm Intern at ByteDance Seed. My research pursues **compiler-driven hardware-software co-design for agile chips**. My current work creates an **extensible benchmark of kernel programming and optimization tasks** for dataflow-architecture chips, develops a layered knowledge and skill system across multiple compilation paths, and builds full-spectrum data collection and training workflows for continual model evolution. The ultimate goal is a **methodology and workflow that enable models and agents to rapidly acquire expert-level kernel optimization capabilities for new chip architectures**.

In **architecture description and exploration**, I combine compiler analysis, formal methods, and architecture DSLs to represent and search design spaces while connecting customized hardware capabilities to programmable software. [ISAMORE](https://doi.org/10.1145/3779212.3790162) (ASPLOS 2026 Best Paper) discovers reusable custom instructions from equivalent program fragments, while [Cayman](https://doi.org/10.1109/DAC63849.2025.11132875) identifies accelerator opportunities in complete applications while co-optimizing control flow and data access. [APS/Aquas](https://aps.ericlyun.me) describes customized architectures through DSLs and exposes them through complete hardware/software compiler stacks.

In **chip DSL and compilation**, I create DSLs and intermediate representations at multiple abstraction levels, then develop compilation and synthesis passes that optimize timing, microarchitecture, implementation selection, mapping, and scheduling. [Hector](https://github.com/pku-liang/Hector) provides a multi-level MLIR foundation for hardware synthesis. [Cement](https://github.com/pku-liang/Cement) couples the cycle-deterministic CmtHDL DSL with the CmtC compiler for timing analysis and control synthesis. Clay and SkyEgg further automate microarchitecture-aware implementation selection and scheduling.

In **compiler optimization and LLM systems**, [EggMind](https://arxiv.org/abs/2604.17364) synthesizes equality-saturation strategies with LLM guidance, and [IntelliC](https://github.com/uv-xiao/IntelliC) studies inspectable compiler representations for human-model collaboration. [Spine](https://github.com/arch-of-shadow/spine) organizes verification-bounded co-synthesis across design intent, architecture, compiler, hardware, and execution evidence. [PTO Runtime](https://github.com/hw-native-sys/simpler) supports dynamic kernel fusion and distributed execution of compiled task graphs on Ascend chips and LingQu SuperPods, while [Hive](https://arxiv.org/abs/2604.17353) provides infrastructure for multi-agent inference workloads.

**Academic service.** I serve on the Student Technical Program Committee of MICRO 2026 and the Technical Program Committee of MLCAD 2026. I also reviewed journal submissions for IEEE TCAD and ACM TECS in 2024.
