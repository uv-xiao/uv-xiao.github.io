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

我是北京大学集成电路学院博士研究生，导师为 [梁云](https://ericlyun.me) 教授；同时在 ByteDance Seed 担任大语言模型算法实习生。当前工作聚焦 **面向新型 AI 芯片上大模型系统的智能体基础设施**，构建用于算子功能实现、芯片架构感知性能优化与工具链自动开发的智能体。目标有两个层面：一方面让新芯片更高效地服务大模型负载，另一方面将智能体研发过程中的数据与 trajectory 沉淀为训练信号，反哺后续 coding 与系统智能体的能力提升。

这个方向把智能体视为大模型基础设施中的系统层，而不只是代码补全工具。智能体需要理解目标芯片与软件栈，生成算子或工具链产物，经由编译器/运行时路径观察效果，并把经验沉淀为可复用的能力。因此，我当前的工作同时驱动 **模型服务效率** 与 **模型能力提升**：同一套基础设施既优化新芯片上的大模型服务，也产生能增强未来模型系统开发能力的 trajectory。

此前的研究构成了这一方向的技术基础。在编译器与形式化方法方面，[ISAMORE](https://doi.org/10.1145/3779212.3790162)（ASPLOS 2026 最佳论文）使用 e-graph 反合一发现可复用自定义指令，[EggMind](https://arxiv.org/abs/2604.17364) 研究大模型引导的等式饱和策略综合。在 IR 与协同设计方面，[Hector](https://github.com/pku-liang/Hector)、[APS/Aquas](https://aps.ericlyun.me) 和 [IntelliC](https://github.com/uv-xiao/IntelliC) 构建显式、可检查的编译表示与软硬件接口。

我也研究连接编译器产物与真实执行的硬件和运行时底座。[Cement](https://github.com/pku-liang/Cement)、Clay 与 SkyEgg 关注硬件综合和架构感知优化，[PTO Runtime](https://github.com/hw-native-sys/simpler) 面向 Ascend 芯片与灵衢 SuperPod 执行编译后的任务图，[Hive](https://arxiv.org/abs/2604.17353) 将系统视角扩展到多智能体大模型推理基础设施。这些工作共同构成了从编译器和硬件基础走向新芯片上大模型基础设施智能体的路径。
