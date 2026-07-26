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

I am a Ph.D. candidate at the School of Integrated Circuits, Peking University, advised by Prof. [Yun Liang](https://ericlyun.me), and a Large Language Model Algorithm Intern at ByteDance Seed. My current research centers on **agents for LLM infrastructure on emerging AI chips**. I contribute to **native multi-agent coding systems**, focusing on multi-agent orchestration strategies and workflow customization through programmable concurrency and human-in-the-loop workflows for long-horizon systems development.

I apply these approaches to **LLM infrastructure on emerging AI chips**. I evolve an abstraction-layered operator-optimization skill system and an agent-native compiler stack for operator implementation, chip-architecture-aware performance optimization, and automated toolchain development. This work improves **model-serving efficiency** on new chips, while real development data and trajectories become training signals for **model-capability improvement**.

My earlier research follows a **compiler-driven approach to agile chip design**: use DSLs and multi-level IRs to expose architecture choices, then build compilation and synthesis stacks that optimize software and hardware together. [Hector](https://github.com/pku-liang/Hector) provides multi-level IRs for hardware synthesis. [Cement](https://github.com/pku-liang/Cement) couples the cycle-deterministic CmtHDL DSL with the CmtC compiler for timing analysis and control synthesis. [APS/Aquas](https://aps.ericlyun.me) builds an MLIR-based stack from architecture DSLs to hardware synthesis and software compilation, then extends it with domain-specific memory/synthesis directives and an e-graph retargetable compiler.

Across this compiler-driven stack, [ISAMORE](https://doi.org/10.1145/3779212.3790162) (ASPLOS 2026 Best Paper) and [EggMind](https://arxiv.org/abs/2604.17364) structure optimization search with formal and LLM-guided methods; Clay, Cayman, and SkyEgg automate microarchitecture and accelerator optimization; and [IntelliC](https://github.com/uv-xiao/IntelliC) makes compiler artifacts inspectable for human-agent collaboration. [PTO Runtime](https://github.com/hw-native-sys/simpler) carries compiled task graphs onto Ascend chips and LingQu SuperPods, while [Hive](https://arxiv.org/abs/2604.17353) and [Spine](https://github.com/arch-of-shadow/spine) extend the story toward multi-agent LLM infrastructure and cross-layer agentic co-design. These systems are now the technical substrate on which my native multi-agent work operates.
