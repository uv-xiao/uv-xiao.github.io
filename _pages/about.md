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

I am a Ph.D. candidate at the School of Integrated Circuits, Peking University, advised by Prof. [Yun Liang](https://ericlyun.me), and a Large Language Model Algorithm Intern at ByteDance Seed. My current work focuses on **agentic infrastructure for LLM systems on emerging AI chips**. I build agents for operator implementation, chip-architecture-aware performance optimization, and automated toolchain development. The goal is twofold: making new chips serve LLM workloads more efficiently, and turning agent development data and trajectories into training signals for stronger coding and systems agents.

This direction treats agents as a systems layer for LLM infrastructure rather than only as coding assistants. An agent should understand the target chip and software stack, produce operator or toolchain artifacts, evaluate the effect through the compiler/runtime path, and accumulate reusable experience for the next generation of agents. In this sense, my current work drives both **model-serving efficiency** and **model-capability improvement**: the same infrastructure that improves LLM service on new chips also produces trajectories that help future models become better systems builders.

My earlier research provides the technical foundation for this agenda. On the compiler and formal-methods side, [ISAMORE](https://doi.org/10.1145/3779212.3790162) (ASPLOS 2026 Best Paper) uses e-graph anti-unification to discover reusable custom instructions, while [EggMind](https://arxiv.org/abs/2604.17364) studies LLM-guided equality-saturation strategy synthesis. On the IR and co-design side, [Hector](https://github.com/pku-liang/Hector), [APS/Aquas](https://aps.ericlyun.me), and [IntelliC](https://github.com/uv-xiao/IntelliC) build compiler representations and workflows that make hardware-software interfaces explicit and inspectable.

I also work on hardware and runtime substrates that connect compiler artifacts to real execution. [Cement](https://github.com/pku-liang/Cement), Clay, and SkyEgg study hardware synthesis and architecture-aware optimization, while [PTO Runtime](https://github.com/hw-native-sys/simpler) targets compiled task-graph execution on Ascend chips and LingQu SuperPods. [Hive](https://arxiv.org/abs/2604.17353) extends this systems view to multi-agent LLM inference infrastructure. Together, these projects form a path from compiler and hardware foundations toward agents that can build, optimize, and improve LLM infrastructure on new chips.
