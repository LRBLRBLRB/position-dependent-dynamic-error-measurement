# Position-dependent Dynamic Error Measurement

本项目用于机床直线轴位置相关动态误差的测量与分析。代码主要基于 MATLAB，包含少量 Python 采集脚本，覆盖轨迹生成、测量数据处理、几何定位误差补偿、统计分析和结果绘图等流程，适合复现实验数据处理过程、整理动态误差指标以及生成论文/报告图表。

## 功能特性

- 生成用于动态性能评估的 jerk-limited S 曲线测试轨迹。
- 处理 IDS-3010 位移测量数据，包括去噪、降采样、几何误差补偿、速度/加速度计算、分段和特征指标提取。
- 处理 Siemens NC/log 数据和 XL-80 定位误差测量数据。
- 拟合几何定位误差曲线，并在后续位移数据处理中进行补偿。
- 对速度、加速度、跃度、方向、测点和滑枕/Y 轴位置等因素进行正交试验、全因子试验和 ANOVA/回归分析。
- 生成 IDS、光栅尺/Siemens、插补结果以及实验设计相关的对比图和结果图。

## 目录结构

```text
.
├── data/                         # 示例数据和中间数据文件
│   ├── statistical-analysis/      # 统计分析使用的表格数据
│   └── test-trajactory/           # 轨迹 CSV 示例数据
├── resources/                    # MATLAB Project 元数据
├── src/
│   ├── 0-common/                 # 通用绘图、保存和滤波辅助函数
│   ├── 1-trajectory-generation/  # S 曲线和 X 轴轨迹生成
│   ├── 2-data-analysis/          # 测量数据处理
│   │   ├── ids-3010/             # IDS 位移数据处理流程
│   │   ├── nc/                   # Siemens NC/log 数据导入与处理
│   │   └── xl-80/                # XL-80 导出数据处理
│   ├── 3-statistical-analysis/   # 正交分析、ANOVA 和不确定度分析
│   ├── 4-result-plot/            # 最终结果绘图脚本
│   ├── accelerator/              # Python TCP 加速度数据采集原型
│   └── geometric_error_fitting.m # 几何定位误差拟合脚本
├── start_up.m                    # 将项目目录加入 MATLAB 路径
├── shut_down.m                   # 从 MATLAB 路径中移除项目目录
└── position-dependent-dynamic-error-measure.prj
```

IDS 数据处理模块的更详细说明见 [`src/2-data-analysis/ids-3010/README.md`](src/2-data-analysis/ids-3010/README.md)。

## 环境要求

### MATLAB

主流程使用 MATLAB 编写。项目没有固定最低版本要求，但代码使用了 `wdenoise`、`spaps`、`fitlm`、`fullfact`、`maineffectsplot` 以及 `.mlx` Live Script，建议使用较新的 MATLAB 版本运行。

常用工具箱包括：

- Signal Processing Toolbox
- Wavelet Toolbox
- Curve Fitting Toolbox
- Statistics and Machine Learning Toolbox
- Optimization Toolbox / Global Optimization Toolbox，部分滤波对比实验会用到
- Parallel Computing Toolbox，启用并行遗传算法选项时会用到

### Python

只有 `src/accelerator/accelerator.py` 使用 Python，依赖：

- Python 3
- `matplotlib`

## 快速开始

1. 克隆仓库：

   ```bash
   git clone https://github.com/<your-org-or-user>/position-dependent-dynamic-error-measurement.git
   cd position-dependent-dynamic-error-measurement
   ```

2. 在仓库根目录打开 MATLAB，或打开 MATLAB Project 文件：

   ```matlab
   openProject("position-dependent-dynamic-error-measure.prj")
   ```

3. 将项目目录加入 MATLAB 路径：

   ```matlab
   run("start_up.m")
   ```

4. 运行需要的处理流程。例如：

   ```matlab
   run("src/1-trajectory-generation/x_trajectory1.m")
   run("src/2-data-analysis/ids-3010/ids_data_process.m")
   run("src/3-statistical-analysis/orthogonal_analysis.m")
   ```

5. 结束后可按需移除项目路径：

   ```matlab
   run("shut_down.m")
   ```

## 主要流程

### 1. 轨迹生成

轨迹生成脚本位于 `src/1-trajectory-generation/`。

- `x_trajectory1.m`、`x_trajectory2.m`、`x_trajectory3.m` 用于生成 X 轴测试轨迹。
- `s_traj_*.m` 实现 S 曲线的位置、速度、加速度、跃度和参数计算。
- 生成的轨迹数据可通过交互式保存窗口导出为 CSV。

运行前请检查脚本开头的运动参数，例如跃度、加速度约束、最大速度、初始位置、运动范围和采样间隔。

### 2. 几何误差拟合

`src/geometric_error_fitting.m` 从 XL-80 测量数据中拟合几何定位误差曲线，并保存包含 `geometric_error_pp` 的 MATLAB `.mat` 文件。

该分段多项式后续可用于 IDS 和 Siemens 数据处理脚本中的定位误差补偿：

```matlab
geometricError = ppval(geometric_error_pp, displacement);
compensatedDisplacement = displacement - geometricError;
```

该脚本中部分输入路径仍是实验时的绝对路径。换用新电脑或新数据集时，请先修改路径。

### 3. IDS-3010 数据处理

IDS 主处理脚本为 `src/2-data-analysis/ids-3010/ids_data_process.m`。

输入 IDS `.mat` 文件至少应包含：

- `Time`
- `Displacement`

处理流程大致如下：

```text
IDS MAT 数据
  -> 小波去噪与降采样
  -> 几何定位误差补偿
  -> 速度和加速度计算
  -> 位移峰谷分段
  -> 速度段提取
  -> 动态指标计算
  -> 加速度峰谷指标提取
  -> 结果表格和图窗导出
```

运行前请根据实验修改文件路径、测点方向/符号设置、几何误差文件路径和分段阈值。

### 4. Siemens / NC 数据处理

Siemens 相关脚本位于 `src/2-data-analysis/nc/`。

- `siemens_data_export.m` 及相关 Live Script 用于处理导出的 Siemens 数据。
- `functions/load_siemens_data.m` 用于导入类 CSV 的 Siemens 日志文件，并提取插补、光栅尺、电流和扭矩通道。
- `src/4-result-plot/fig_comparison_ids_siemens.m` 用于在滤波、补偿和时间对齐后比较 IDS、Siemens/光栅尺和插补结果。

### 5. 统计分析

统计分析脚本位于 `src/3-statistical-analysis/`。

- `orthogonal_analysis.m` 构造因素表，并执行回归、交互作用和 ANOVA 风格分析。
- `demo_anova.mlx` 和 `demo_nomality.mlx` 提供探索性 Live Script 示例。
- `uncertainty_analysis.m` 包含用于估计小波去噪引入不确定度的 Monte-Carlo 示例。

该模块的输入表格位于 `data/statistical-analysis/`。

### 6. 结果绘图

论文或报告图表脚本位于 `src/4-result-plot/`。

这些脚本用于从处理后的数据中重新生成部分结果图，可能包含与具体实验相关的路径或参数假设。

## 数据说明

仓库中包含部分示例数据和中间结果数据，但不一定包含完整的大体积原始测量文件。部分脚本最初面向特定实验目录编写，仍包含类似本地 `D:\...` 的绝对路径。复用时请注意：

- 将硬编码路径替换为自己的数据路径；
- 检查每个测点的信号方向和符号约定；
- 核对速度、加速度、跃度和分段阈值；
- 当机床轴、测量配置或测量范围发生变化时，重新生成 `geometric_error_pp`。

## 代码说明

本仓库更接近研究代码集合，而不是已经封装好的 MATLAB toolbox。多数入口是脚本而非参数化函数。建议在复现实验或处理新数据时，从相关脚本复制或新建分支，修改脚本开头的实验参数，并尽量将生成结果保存在源代码目录之外。

## 贡献

欢迎提交 issue 或 pull request。比较有价值的改进包括：

- 将硬编码路径改为配置文件或函数参数；
- 为各个流程补充小型示例数据；
- 为输入变量增加自动检查；
- 在处理脚本中补充测量约定和单位说明；
- 为可复用辅助函数添加测试。

## 许可证

本项目采用 GNU Lesser General Public License v2.1 开源许可证。详情见 [`LICENSE`](LICENSE)。
