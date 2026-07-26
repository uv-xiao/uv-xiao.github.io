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

我是北京大学集成电路学院博士研究生，导师为 [梁云](https://ericlyun.me) 教授；同时在 ByteDance Seed 担任大语言模型算法实习生。当前研究聚焦于 **面向新型 AI 芯片 LLM 基础设施的智能体**。我参与 **原生多智能体 coding agent 系统** 的研发，主要关注多智能体编排策略与工作流定制，以程序化并发和 human-in-the-loop 工作流支撑长程系统研发。

我将这些方法用于 **新型 AI 芯片上的 LLM 基础设施**：演进抽象分层的算子优化 skill 系统，以及 agent 原生编译体系，贯通算子实现、芯片架构感知性能优化和工具链自动开发。它提升新芯片上的 **模型服务效率**，同时将真实研发数据与 trajectory 转化为推动 **模型能力提升** 的训练信号。

此前的研究遵循 **编译器驱动的敏捷芯片设计** 主线：以领域专用语言和多层次 IR 暴露架构选择，再搭建贯通软件与硬件的编译、综合栈，实现协同优化。[Hector](https://github.com/pku-liang/Hector) 提供面向硬件综合的多层次 IR；[Cement](https://github.com/pku-liang/Cement) 将周期确定的 CmtHDL 领域专用语言与具备时序分析、控制综合能力的 CmtC 编译器结合；[APS/Aquas](https://aps.ericlyun.me) 构建从架构 DSL 到硬件综合和软件编译的 MLIR 栈，并进一步加入面向领域的访存/综合指令与基于 e-graph 的可重定向编译器。

沿着这条编译器驱动的技术栈，[ISAMORE](https://doi.org/10.1145/3779212.3790162)（ASPLOS 2026 最佳论文）与 [EggMind](https://arxiv.org/abs/2604.17364) 分别以形式化方法和大模型引导方法组织优化搜索；Clay、Cayman 与 SkyEgg 自动化微架构和加速器优化；[IntelliC](https://github.com/uv-xiao/IntelliC) 则让编译器产物可被人与智能体共同检查。[PTO Runtime](https://github.com/hw-native-sys/simpler) 将编译后的任务图部署到 Ascend 芯片与灵衢 SuperPod，[Hive](https://arxiv.org/abs/2604.17353) 和 [Spine](https://github.com/arch-of-shadow/spine) 进一步走向多智能体大模型基础设施与跨层智能体协同设计。这些系统如今构成了原生多智能体工作可直接操作的技术底座。
