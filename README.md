# GMSK_Total

GMSK 通信系统 FPGA/Matlab/ModelSim 仿真与验证工程。

本仓库主要用于 GMSK 调制、解调、LLR 计算、帧结构处理以及相关 FPGA RTL 仿真与算法验证，包含 Verilog/SystemVerilog、ModelSim 仿真工程、Vivado 工程及 MATLAB 验证代码。

## 项目内容

目前工程主要涉及以下部分：

* GMSK 调制器
* GMSK 解调与软判决
* LLR（Log-Likelihood Ratio）计算
* 帧结构与业务数据处理
* ModelSim RTL 仿真
* MATLAB 算法验证
* Vivado FPGA 工程
* GMSK 发射/接收链路联合验证
* AWGN 条件下的 BER 性能验证
* 跳频及频点控制相关逻辑

## 工程环境

主要开发和验证环境：

* MATLAB R2024b
* ModelSim SE-64 2020.4
* Xilinx Vivado
* Verilog / SystemVerilog
* Windows 11

部分 MATLAB 与 RTL 联合仿真使用 HDL Verifier。

## 目录说明

仓库中不同目录对应不同阶段的设计与验证工程。

例如：

```text
GMSK_Total/
├── GMSK_modelsim_transfer_20260909/
│   └── ModelSim / GMSK 联合仿真相关文件
│
├── LLR_top_simple.srcs/
│   └── Vivado LLR 计算相关工程文件
│
├── ...
│
├── .gitignore
└── README.md
```

具体目录可能随着项目开发继续调整。

## GMSK 处理流程

整体链路可概括为：

```text
Input Bits
    │
    ▼
GMSK Modulator
    │
    ▼
I/Q Baseband Samples
    │
    ▼
Channel / AWGN
    │
    ▼
GMSK Demodulator
    │
    ▼
LLR Calculation
    │
    ▼
Soft Decision / Bit Decision
    │
    ▼
BER Verification
```

部分测试同时结合帧结构、同步信息、跳频频点以及业务数据进行端到端验证。

## ModelSim 仿真

ModelSim 主要用于 RTL 功能验证。

工程中包含 GMSK 发射、接收、LLR 以及帧处理模块的 testbench 和仿真脚本。

典型流程：

```bash
vlog -sv -f <filelist>
vsim <testbench>
run -all
```

具体顶层和 filelist 根据对应测试工程选择。

## MATLAB 验证

MATLAB 主要用于：

* 随机比特生成
* GMSK 调制算法验证
* AWGN 信道模拟
* GMSK 解调
* LLR 验证
* BER 统计
* MATLAB / ModelSim Co-Simulation
* 仿真数据绘图及分析

部分测试会遍历不同 SNR，通过接收比特与原始发送比特比较获得 BER 曲线。

## FPGA / Vivado

Vivado 工程主要用于相关 RTL 模块的：

* 综合
* 实现
* 时序分析
* FPGA 功能验证

Vivado 自动产生的大量中间文件通常不需要纳入 Git 版本管理。

## 大文件说明

仿真过程中可能生成较大的数据文件，例如：

```text
data_lp_out_1.txt
```

以及 Vivado Design Checkpoint：

```text
*.dcp
```

这类文件通常属于仿真结果或可重新生成的工程中间文件，不建议直接提交到普通 Git 仓库。

建议通过 `.gitignore` 排除：

```gitignore
# ModelSim generated files
*.wlf
transcript
work/

# Simulation output
data_lp_out_1.txt

# Vivado generated files
*.dcp
.Xil/
*.cache/
*.runs/
*.sim/
*.hw/

# MATLAB temporary files
*.asv
slprj/
codegen/
```

如果确实需要管理大型二进制文件，建议使用 Git LFS。

## Git 使用

提交本地修改：

```bash
git status
git add .
git commit -m "Update GMSK design"
git push
```

查看当前分支：

```bash
git branch
```

查看远程仓库：

```bash
git remote -v
```

## Repository

GitHub:

```text
Biayeqing/GMSK_Total
```

## Notes

本工程处于持续开发与验证阶段，不同目录可能保存不同阶段的算法、RTL 实现及测试版本。

建议在对模块进行重大修改时保留清晰的 Git commit 信息，便于后续版本比较、问题定位以及设计回退。
