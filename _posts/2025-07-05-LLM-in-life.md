---
layout: post
title: LLM in very daily life? Enjoy Claude Code and Gemini-cli's super power!
date: 2025-07-05 00:00:00
description: Share an expierence of using LLM agents for life (rather than for work)
tags:
categories:
tabs: true
thumbnail:
mermaid:
  enabled: true
  zoomable: true
toc:
  beginning: true
  # sidebar: left
pretty_table: true
tikzjax: true
pseudocode: true
---

这篇文章记录了我用LLM agents开发一个极简应用（甚至谈不上应用，只是一个简单的程序），~~用来激励女票的考公复习~~。因为考公这个事也非常中国特色，代码也都是中文，所以这个blog也就不用~~翻译成~~英文了。

当前效果：[github.com/uv-xiao/cse-incentive-agent](https://github.com/uv-xiao/cse-incentive-agent)

## LLM Agents

使用LLM agents ([Claude Code](https://www.anthropic.com/claude-code) 和 [Gemini CLI](https://github.com/google-gemini/gemini-cli))做科研（写代码、写论文）是非常方便且生产力爆炸的实践。我会写另一篇blog来描述我最近用他们做科研代码开发的经历。

## 背景：考公激励

前几天女票发我了一个小红书笔记：[笔记链接](https://www.xiaohongshu.com/discovery/item/6862b8f50000000023004419?source=webshare&xhsshare=pc_web&xsec_token=CBVBdciZz6KZBOI7BAFkOBHM0JbYN2EbkL2IXJKMPE0uM=&xsec_source=pc_share)


<div class="row mt-3">
    <div class="col-sm mt-3 mt-md-0">
        {% include figure.liquid loading="eager" path="assets/img/in_posts/2025-07-05-cse_incentive.jpg" class="img-fluid rounded z-depth-1" %}
    </div>
</div>

我寻思这要是我自己天天帮她记录也怪麻烦的，而且也不能提供足够的情绪价值。于是我决定用LLM agents来实现这个功能，并且要求它们提供充分的情绪价值嘿嘿

## 实现

### 安装Claude Code和Gemini CLI

首先就是要setup一些LLM agents。去各自的网站下载安装，发挥梯子的本事和蹭别人会员（Claude Code Max要200刀一个月wtf）的脸皮。我是二者混合使用的（Claude Code写代码和维护项目，生成的代码调用Gemini CLI实现文字类功能），但只用Gemini CLI好像也没问题，毕竟就是写点小Python，也不太需要调工具调试。

### 初始化项目

最开始我创建的文件结构：
```
cse_incentive/
├── .claude/
├──── settings.local.json
├── resources/
├──── red_notebook_image.jpg
├── README.md
```
也就是把那个小红书图片放进resources文件夹，在`.claude`文件夹里粘贴一个`settings.local.json`（设置`"permissions"`的`"defaultMode"`为`"bypassPermissions"`），然后写一个`README.md`。

`README.md`的内容：

```markdown
# ZZW考公Agent

ZZW考公需要好好学习，因此需要激励和监督。

本项目作为ZZW考公的Agent，使用Claude Code驱动，实现考公学习期间的情感支持和进度跟进。

## 资源

`resources/red_black_list.jpg`是一张图片，是网上找的，内容是对不同考公学习期间的行为的加分/扣分，以及基于积分的鼓励。

可以在网上检索更多相关的考公相关的事件、安排、激励、惩罚等，添加到`resources`目录，作为参考。

## 功能

**每日问卷**：生成每日问卷，交给ZZW填写，根据问卷内容生成每日总结。
- 问卷形式应该减少ZZW填写的难度，以选择填空为主。
- 问卷内容是对当天考公内容学习时长、做题情况、情绪状态、身体状态、学习计划完成情况等。
- 问卷应该提供充足的情绪价值，以鼓励ZZW继续学习。

**每日总结**：根据每日问卷内容，生成每日总结报告。
- 总结内容应剖析ZZW的学习、做题、情绪、身体状态，并给出改进建议。
- 总结内容应提供充足的情绪价值，以鼓励ZZW继续学习。
- 报告应为pdf格式，包括emoji和图片等元素，呈现丰富多彩的视觉效果。

**积分奖励/惩罚**： 根据每日问卷内容，生成积分奖励/惩罚。
- 积分奖励/惩罚应根据问卷内容，给出相应的奖励/惩罚。
- 需要在"每日总结"中描述积分奖励/惩罚的原因。
- 积分表需要有积分变化曲线，以直观展示ZZW的积分变化。
- 积分表存储为本地文件，并提供程序编辑和可视化。

## 技术栈

- Claude Code
  - 实现所需的文件结构和代码
  - 每日根据"question", "answer:<answer from zzw>", 生成报告，并调用程序更新积分表。
  - 报告生成过程也可以查看积分表。

- Gemini-cli
  - 由于gemini-cli有更好的语言理解能力和图片生成能力，因此生成报告时，调用gemini-cli实现问卷解析、报告生成、图片生成。

- 代码
  - 使用python实现积分表的存储、更新、可视化。
```

### 让LLM开干

> `/init` 
{: .block-tip }

初始化Claude Code，生成`CLAUDE.md`，里面包含Claude Code自己分析设计的项目结构和功能:

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Civil Service Exam Study Agent (考公Agent) designed to support ZZW in their civil service exam preparation journey. The system provides daily questionnaires, generates encouraging summary reports, and maintains a points-based reward/punishment system to gamify the study process.

## Development Commands

Since this is a Python project in early development, common commands will include:

python -m venv venv
source venv/bin/activate  # On Linux/Mac

pip install -r requirements.txt

python main.py

pytest tests/


## Architecture & Core Components

The system consists of three main functional modules:

### 1. Daily Questionnaire Module
...

### 2. Summary Report Generator
...

### 3. Points Management System
...

## Important Implementation Notes

1. **Scoring Rules**: The red_black_list.jpg contains detailed scoring criteria that must be implemented exactly as shown, including...

2. **Data Persistence**: Implement a simple file-based storage system (JSON or SQLite) to maintain...

3. **Report Generation**: Use gemini-cli for creating visually appealing PDF reports with...

4. **User Experience**: Keep the questionnaire simple and quick to complete to ensure daily compliance.

## External Tool Integration

- **gemini-cli**: Used for generating summary reports and creating visual content
- **Claude Code**: Primary development environment for implementation

## File Structure (Planned)

diary/
├── main.py                 # Entry point
├── modules/
│   ├── questionnaire.py    # Daily questionnaire generation
│   ├── scoring.py          # Points calculation logic
│   ├── report_generator.py # PDF report creation
│   └── data_manager.py     # Data persistence
├── data/                   # Store user responses and points
├── reports/                # Generated PDF reports
└── resources/              # Static resources including red_black_list.jpg
```

看起来已经不错了，初具雏形！但我比较喜欢用[pixi](https://pixi.sh/latest/)来管理项目，于是我让Claude Code使用它:

> `update CLAUDE.md with pixi-based python management.`
{: .block-tip }


接下来就让Claude Code完成代码实现。

> `read @README.md carefully, know what i want, and search things online (use builtin tools and gemini) to collect more resources. Then implement the required codebase. Also update CLAUDE.md to make the claude code to serve well / be qualified for the described job. Also generate a USAGE.md to instruct the subsequent colaboration between I and claude code. `
{: .block-tip }

这一个指令就能让Claude Code完成项目初始化、代码实现、文档撰写等所有工作。

可以查看下生成的`USAGE.md`中关于使用方法的说明:

```markdown
### 每日学习流程
1. **早晨规划**
   - 打开系统，查看昨日报告和积分
   - 制定今日学习计划
2. **晚上总结**
   - 运行程序：`pixi run python main.py`
   - 选择 "1. 填写今日问卷"
   - 认真回答14个问题（约2-3分钟）
   - 查看生成的报告和获得的积分
3. **查看进度**
   - 选择 "3. 查看积分历史" 查看最近记录
   - 选择 "6. 可视化进度" 生成进度图表
```

这里有个问题，因为我这个工具是需要使用Claude Code做更新并使用Gemini CLI生成报告的，这俩工具都能跑的环境其实是我在学校的服务器，而不是ZZW的电脑！（而且也不打算教会ZZW使用命令行和Python这些东西）。总而言之，我才是这个工具的直接用户，总不能每天把生成的问卷一个题一个题微信给ZZW吧！所以我觉得应该让这个工具支持Excel格式的问卷导出和导入。

> `由于ZZW不会使用python，每日运行main.py时，应该生成需要回答的问题的文本格式（比如excel），我会发送给zzw进行回答；然后python程序应该能识别回答后的文件，提取其中的答案，并完成报告生成和积分更新。此外，不但需要等级系统，还需要积分兑换系统（根据resources/red_black_list.jpg）和网上资源，查找可以兑换的奖励；claude也需要支持更新奖励列表。完成上述更新后，更新USAGE.md和README.md以保持最新。`
{: .block-tip }

好了！我们已经得到了这个工具的初步版本（也是github repo的第一个commit），可以让ZZW试用了哈哈

### 改进

执行`pixi run python main.py`，得到：
```bash
欢迎使用 ZZW考公学习日记系统！

这是你的专属学习伙伴，我会陪伴你走过考公之路。
让我们一起努力，向着目标前进！💪

🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟🌟
============================================================
🎯 ZZW考公学习日记系统
============================================================


📋 主菜单:
💰 当前积分: 0分
----------------------------------------
1. 📤 导出今日问卷 (Excel)
2. 📥 导入问卷答案 (Excel)
3. 🎁 查看积分商城
4. 🛒 兑换奖励
5. 📄 查看今日报告
6. 📊 查看积分历史
7. 📈 查看学习统计
8. 📅 生成周总结
9. 📉 可视化进度
10. 💾 导出数据
0. 退出系统
```
啧啧这情绪价值拉满！

我把生成的问卷发给了ZZW，有一些修改的意见，我直接发给Claude Code，让他调整：

> `删除小额奖励和中等奖励`
{: .block-tip }

> `我希望删除的不是积分奖励，而是积分兑换系统里的小额奖励和中等奖励`
{: .block-tip }

> `ZZW提出了如下反馈：学习时间和练习题的选项数值都太低了，她每天都是远超问卷选项中的数量，需要大幅提高；除了做题之外，ZZW还同时需要写她的毕业论文，需要添加对应的积分奖励（比如与每日创作多少字数关联）；ZZW还会背诵考公需要的知识，或者看网课学习，请上网查找相关信息，并添加积分奖励。请根据上述反馈更新工具。`
{: .block-tip }

> `目前积分奖励和惩罚的积分数值差别很大，请适当提高积分惩罚以示警戒`
{: .block-tip }

这些就不太重要了！

## 结论

也没啥结论可下，总之就是在把LLM当问答助手之外，可以尝试用它来实现一些日常生活中的小工具，比如这个考公激励工具。但这也确实需要写门槛，至少得能访问现在这几个比较猛的LLM Agents（希望国内的公司加加油，来点deepseek code, qwen-cli, ~~doubao~~之类的），还要有一点代码开发基础（至少能调这些cli或者运行生成的程序？好吧，可能也不需要，如果LLM直接搞出来个什么网页、小程序之类的）。

