---
layout: about
title: 关于
display_title: 肖有为
permalink: /zh/
subtitle:
lang: zh-CN
nav: false
language_switch:
  - label: English
    url: /
  - label: 中文
    url: /zh/
    active: true

profile:
  align: right
  image: self_at_fuzhou.jpg
  image_circular: true
  more_info: >
    <p><span class="profile-name-en">Youwei Xiao</span> <span class="profile-name-zh">肖有为</span></p>
    <p>北京大学集成电路学院</p>
    <p>北京，中国</p>

news: true
selected_papers: true
social: true
---

我是北京大学集成电路学院博士研究生，导师为 [梁云](https://ericlyun.me) 教授；2022 年于北京大学获得电子信息科学与技术学士学位。我的研究围绕敏捷芯片设计与编译优化的软硬件协同展开：从真实软件负载中发现架构定制机会，将定制能力综合为可实现的硬件，并通过编译器与系统软件让这些能力服务于实际应用。

我的第一条工作线关注 **硬件综合**。我构建面向 EDA 的软件抽象，将高层设计意图连接到高效 RTL 级硬件实现，包括高层次综合框架 [Hector](https://github.com/pku-liang/Hector)（ICCAD 2022）、Rust 硬件描述语言 [Cement](https://github.com/pku-liang/Cement)（FPGA 2024），以及 SkyEgg 中基于 e-graph 的综合优化。围绕这些工作，我使用 MLIR、Rust 与编译器 IR 设计，让硬件综合过程更可编程、可分析、可优化。

第二条工作线关注 **架构定制**。我探索如何用编译分析、应用画像、设计空间搜索和形式化方法，自动发现有价值的加速器与自定义指令。[Cayman](https://doi.org/10.1109/DAC63849.2025.11132875)（DAC 2025）在考虑控制流与数据访问策略的同时生成领域专用加速器；[ISAMORE](https://doi.org/10.1145/3779212.3790162)（ASPLOS 2026）使用 e-graph 反合一从等价程序片段中发现可复用的自定义指令。

这两条线共同指向更完整的协同设计目标：从敏捷规格甚至目标应用出发，自动推导架构设计、硬件实现与编译器支持。我与实验室同学共同发起并推进 [APS 项目](https://aps.ericlyun.me)，希望以尽可能少的人工介入，为目标机器学习模型生成优化的 ML ASIC 方案并配套完整 ML 编译支持。我也参与组织 EDA 与体系结构会议教程，介绍敏捷硬件专用化和软硬件协同设计方法，相关材料见 [APS tutorials](https://aps.ericlyun.me/tutorials/)。

近期，我将这一研究议程推进到 **LLM 时代的编译器与系统技术**。一方面，我研究 LLM 与智能体如何成为编译优化和软硬件协同设计的新接口，包括用于等式饱和策略综合的 [EggMind](https://arxiv.org/abs/2604.17364)，以及面向下一代 APS 和 Spine 的智能体协同设计流程。另一方面，我研究面向新兴机器学习负载的编译器与运行时系统，包括 [IntelliC](https://github.com/uv-xiao/IntelliC) 中面向人与智能体协作的可检查编译表示，[PTO Runtime](https://github.com/hw-native-sys/simpler) 中面向 Ascend 芯片与灵衢 SuperPod 的分布式服务任务图执行，以及 [Hive](https://arxiv.org/abs/2604.17353) 中面向多智能体系统推理的编程界面和控制层基础设施。
