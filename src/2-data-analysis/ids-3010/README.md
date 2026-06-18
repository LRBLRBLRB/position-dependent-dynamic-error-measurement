# IDS 测量数据 MATLAB 处理程序

本目录用于处理由 TDMS 数据转换得到的 IDS 位移测量结果。当前主流程从位移序列出发，依次完成去噪、降采样、几何定位误差补偿、速度与加速度计算、运动分段、特征指标提取和结果绘图。

## 主处理流程

主入口为 `ids_data_process.m`，大致调用关系如下：

```text
IDS MAT 数据（Time、Displacement）
  -> 小波去噪与降采样
  -> 几何定位误差补偿
  -> 速度、加速度计算
  -> peak_segmentation / plot_peaks
  -> velocity_segmentation / remove_adjacent
  -> velo_param
  -> accel_param2excel 或 accel_param2excel_C
  -> save_excel、fig_save、fig_tiled、fig_modal
```

## 运行前准备

1. 在 `ids_data_process.m` 中修改 `FILE_PATH`，使其指向待处理的 IDS `.mat` 文件。
2. 输入 MAT 文件至少应包含等长的 `Time` 和 `Displacement` 数组。
3. 检查脚本开头的测点方向修正。A、B、C、D 测点使用的符号和起始位置不同，相关代码当前需要手动选择。
4. 检查峰值显著性、相邻点距离和波动模式等参数是否适合当前试验。
5. 确认 `GEOMETRIC_ERROR_MAP` 指向几何误差拟合文件，且文件中包含分段多项式 `geometric_error_pp`。

脚本通过 `addpath(genpath('../..'))` 使用 `data-analysis` 目录中的公共函数，包括：

- `save_excel.m`：整理位移和速度指标。
- `fig_save.m`：保存处理过程中生成的图窗。
- `fig_tiled.m`：平铺图窗。
- `fig_modal.m`：调整图窗显示方式。

主要工具箱依赖包括 Signal Processing Toolbox、Wavelet Toolbox 和 Curve Fitting Toolbox。`ids_filter_sg.m` 还需要 Global Optimization Toolbox；其中的并行遗传算法配置需要 Parallel Computing Toolbox。

## 文件说明

### 当前主流程

| 文件 | 作用 |
| --- | --- |
| `ids_data_process.m` | 当前 IDS 数据处理主脚本。读取位移 MAT 数据，统一测量方向，小波去噪并降采样，补偿几何定位误差，计算速度和加速度，提取位移峰谷、速度动态指标及加速度指标，最后整理指标并保存图像。输入路径、测点方向和部分阈值需要按试验手动调整。 |
| `peak_segmentation.m` | 通用峰谷检测函数。基于 `findpeaks` 提取位移或加速度信号的峰值、谷值、时刻、宽度、显著性、索引、类别值和误差；可以返回合并后的时序表，也可以分别返回峰值表和谷值表。 |
| `plot_peaks.m` | 绘制原始信号、已识别的峰谷位置及峰谷误差柱状图。被 `peak_segmentation.m` 和 `accel_segmentation.m` 调用。代码使用了 MATLAB 的内部接口 `signal.internal.findpeaks.plotpkmarkers`，MATLAB 升级后可能需要检查兼容性。 |
| `velocity_segmentation.m` | 根据速度曲线的过零点和速度等级划分速度变化段，并推断各段的目标速度（约为正负 5000 或 30000 mm/min）。输出每段的起止索引、目标速度和有效数据末端索引。 |
| `remove_adjacent.m` | 合并距离过近的候选过零点。在每组相邻候选点中，根据附近速度变化幅度保留一个代表点，供 `velocity_segmentation.m` 使用。 |
| `velo_param.m` | 计算单个速度变化段的动态指标，包括峰值及误差、峰值时刻、稳态值及误差、上升时间、噪声水平、超调量、主频和调节时间等。 |
| `accel_param2excel.m` | 面向常规 A、B、D 等测点，从加速度峰谷表中按低速/高速、正向/逆向选取代表性峰值，计算平均峰值、峰值间隔和峰宽，生成供最终指标表拼接的 6 列数组，同时绘制提取过程。 |
| `accel_param2excel_C.m` | C 测点专用的加速度指标整理函数。使用位移峰值时刻划分每个往返段，再分别汇总低速/高速和正向/逆向的加速度峰值、间隔与峰宽。 |

### 辅助及备用函数

| 文件 | 作用 |
| --- | --- |
| `accel_segmentation.m` | 较早的加速度专用峰谷分段函数，根据理论加速度设置峰值显著性并输出峰谷表。当前主脚本改用更通用的 `peak_segmentation.m`，因此该文件主要作为旧实现保留。 |
| `filter_gaussian.m` | 对一维序列执行手写高斯卷积滤波，序列两端不处理。当前主脚本中仅保留了相关注释，未实际调用。 |
| `velo_cal.m` | 仅通过一阶差分计算 `v = diff(x)./diff(t)` 的早期辅助函数。文件名为 `velo_cal.m`，函数名却是 `cal_velo`，命名不一致，因此不建议作为当前流程入口。 |

### 滤波方法对比实验

以下脚本都包含硬编码的数据路径，主要用于比较不同位移/速度平滑方法，不属于当前批处理流程。

| 文件 | 作用 |
| --- | --- |
| `ids_filter_move.m` | 测试移动平均滤波。遍历不同奇数窗口，以滤波后位移一阶差分的标准差作为评价指标，选择最佳窗口，并绘制位移、速度和加速度结果。 |
| `ids_filter_sg.m` | 测试 Savitzky-Golay 滤波。使用遗传算法联合优化多项式阶数和窗口长度，目标函数兼顾位移残差及速度高频能量，并绘制滤波后的运动量。 |
| `ids_filter_spline.m` | 测试平滑样条拟合。使用 `spaps` 拟合降采样后的位移，并通过样条导数估计速度和加速度。 |
| `ids_filter_wavelet.m` | 测试小波去噪。先使用 `wdenoise` 平滑位移，再对差分速度进行平滑样条拟合，最后比较原始与滤波后的位移、速度和加速度。 |

### 理论轨迹

| 文件 | 作用 |
| --- | --- |
| `theo_path.m` | 根据给定时间节点和位移节点生成全局等间隔采样的 jerk-limited S 曲线。每个非零位移段均按静止到静止规划，受最大跃度和最大加速度约束；脚本绘制理论位移、速度、加速度，并保存理论轨迹。 |
| `theo_path.mat` | 由 `theo_path.m` 生成的 MATLAB 7.3 数据文件，保存理论时间序列 `theo_t` 和理论位移序列 `theo_disp`。修改轨迹节点、约束或采样周期后应重新运行脚本生成该文件。 |

### 旧版和试验文件

| 文件 | 作用 |
| --- | --- |
| `ids_data_process_old.mlx` | 早期 IDS 处理 Live Script。内容主要是读取并绘制位移、调用旧的位移分段函数，以及通过差分计算速度；功能已由 `ids_data_process.m` 扩展和替代。 |
| `test.mlx` | 测量数据预处理试验 Live Script。测试 timetable、降采样、小波去噪，以及通过局部函数计算位移、速度、加速度和跃度。 |
| `ids_data_process.asv` | MATLAB 自动保存的 `ids_data_process.m` 临时版本，其中还保留了信噪比估计等试验代码。它不是正式入口，正常使用时应运行 `.m` 文件。 |

### `test_quantization` 子目录

该目录用于探索位移量化误差对差分速度的影响，代码整体仍处于试验或草稿状态。

| 文件 | 作用 |
| --- | --- |
| `test_quantization/fourier_smoothness.m` | 对输入信号进行傅里叶变换，保留 2 Hz 以下频率并抑制高频成分，然后绘制原始信号与滤波结果。 |
| `test_quantization/kalman_filter.m` | 二状态矩阵形式的卡尔曼滤波器，循环执行预测和更新，输出每个采样点的状态估计与协方差；设计目标是联合估计位移和速度。 |
| `test_quantization/kalman_filter_obj.m` | 卡尔曼滤波目标函数的占位模板，目前只原样返回两个输入，没有实际优化逻辑。 |
| `test_quantization/quantization_cost.m` | 量化噪声滤波评价函数草稿，计划综合位移残差和速度残差。当前代码包含未定义变量 `z` 和未清理的占位字符，不能直接运行。 |

## 主要输出

运行 `ids_data_process.m` 后，工作区中主要包含：

- `idsData`：处理后的位移、速度、滤波速度和加速度数据。
- `dispPeaks`：位移峰谷及误差表。
- `velocitySegment`、`desiredValue`：速度分段结果及目标速度。
- `veloParam`：各速度段的动态指标表。
- `accelPeaks`、`accelValleys`：加速度峰值和谷值表。
- `paramExcel`：合并后的位移、速度和加速度指标。

脚本还会在输入 MAT 文件同级目录下创建同名文件夹，并通过 `fig_save` 保存生成的图窗。

## 使用注意

- 当前流程依赖试验文件命名规则，并通过文件名中的 `A<number>` 提取理论加速度。
- 速度分段中的 5000、30000 mm/min 等阈值，以及加速度峰值的组合规则，都是针对现有试验轨迹编写的；更换运动程序后需要同步修改。
- 主脚本目前是交互式单文件处理脚本，不是通用批处理函数。
- `ids_filter_*.m`、Live Script 和 `test_quantization` 中的路径或参数多为试验时的固定值，运行前必须检查。
