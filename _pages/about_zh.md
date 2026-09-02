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

我是北京大学集成电路学院博士研究生，导师为 [梁云](https://ericlyun.me) 教授；同时在 ByteDance Seed 担任大语言模型算法实习生。我的研究方向是 **编译器与软硬件协同优化、大模型驱动编译优化与算子生成**。当前工作创建面向数据流架构芯片、覆盖算子编程与优化任务的 **可扩展 Benchmark**，构建多编译路径的分层知识与技能系统，以及全场景的数据采集与训练工作流，以持续演进模型能力。最终目标是 **构建一套方法与流程，使模型与智能体能够快速具备面向新芯片架构的专家级算子优化能力**。

在 **架构描述与探索** 方向，我结合编译分析、形式化方法和架构 DSL，表示并搜索设计空间，并将定制硬件能力连接到可编程软件。[ISAMORE](https://doi.org/10.1145/3779212.3790162)（ASPLOS 2026 最佳论文）从等价程序片段中发现可复用自定义指令；[Cayman](https://doi.org/10.1109/DAC63849.2025.11132875) 从完整应用中发现加速器机会，并协同优化控制流和数据访问；[APS/Aquas](https://aps.ericlyun.me) 则通过 DSL 描述定制架构，并以完整软硬件编译栈暴露其可编程能力。

在 **芯片设计语言与编译** 方向，我在多个抽象层次设计领域专用语言和中间表示，并提出编译与综合 pass，用于优化时序、微架构、实现选择、映射与调度。[Hector](https://github.com/pku-liang/Hector) 为硬件综合提供多层次 MLIR 基础；[Cement](https://github.com/pku-liang/Cement) 将周期确定的 CmtHDL 领域专用语言与具备时序分析、控制综合能力的 CmtC 编译器结合；Clay 与 SkyEgg 进一步自动化微架构感知的实现选择与调度。

在 **编译优化与 LLM 系统** 方向，[EggMind](https://arxiv.org/abs/2604.17364) 使用大模型生成 equality-saturation 优化策略，[IntelliC](https://github.com/uv-xiao/IntelliC) 研究面向人与模型协作的可检查编译表示；[Spine](https://github.com/arch-of-shadow/spine) 以验证边界组织设计意图、架构、编译器、硬件与执行证据之间的协同生成；[PTO Runtime](https://github.com/hw-native-sys/simpler) 面向 Ascend 芯片和灵衢 SuperPod，支持编译任务图的动态算子融合与分布式执行，[Hive](https://arxiv.org/abs/2604.17353) 则提供面向多智能体推理负载的基础设施。

**学术服务。** 担任 MICRO 2026 学生技术程序委员会委员和 MLCAD 2026 技术程序委员会委员；并于 2024 年为 IEEE TCAD 和 ACM TECS 提供期刊评审。
