# Position-dependent Dynamic Error Measurement

本仓库负责机床位置相关动态误差的**测量、预处理、辨识和统计分析**。它的边界是生产可信的测量数据和测量结论，而不是承担 Adams 或动力学预测流程。

在当前三个仓库的分工中，本仓库是数据生产端：

```text
position-dependent-dynamic-error-measurement
  -> 处理 IDS / Siemens / XL-80 等测量数据
  -> 导出稳定的 measurement release
  -> 供 flex-rigid-multibody-dynamics 读取和用于仿真对比
```

公共函数应逐步沉淀到相邻仓库 `../machine-tool-error-core`。预测仓库不应直接调用本仓库中的脚本或函数，而应只读取本仓库导出的标准数据文件。

## Repository Role

本仓库保留以下职责：

- 规划和生成测量用测试轨迹。
- 读取 IDS-3010、Siemens NC/log、XL-80 等实验数据。
- 对测量位移进行去噪、降采样、几何定位误差补偿、速度/加速度计算。
- 提取位移峰谷、速度段、加速度峰值等动态误差指标。
- 进行正交试验、全因子试验、ANOVA、回归和不确定度分析。
- 生成测量侧论文图和报告图。
- 向预测仓库导出稳定的数据产品。

本仓库不负责：

- Adams 模型维护和仿真运行。
- 自编程刚柔耦合动力学建模。
- 动态误差预测模型主体。
- 预测侧仿真结果与测量结果的最终对比流程。

## Relationship With Other Repositories

```text
machine-tool-error-core
  Public MATLAB functions, shared data conventions, small calibration data

position-dependent-dynamic-error-measurement
  Measurement workflows and exported measurement releases

flex-rigid-multibody-dynamics
  Adams simulation, MATLAB dynamics models, prediction, and comparison plots
```

推荐依赖方向：

```text
position-dependent-dynamic-error-measurement -> machine-tool-error-core
flex-rigid-multibody-dynamics                -> machine-tool-error-core
flex-rigid-multibody-dynamics                -> exported measurement data
```

不推荐：

```text
flex-rigid-multibody-dynamics -> position-dependent-dynamic-error-measurement/src
```

这样可以保证测量库内部处理流程改变时，只要导出数据格式稳定，预测库就不需要跟着修改。

## Directory Structure

```text
.
├── data/
│   ├── 1-test-trajactory/          # Test trajectory CSV examples
│   └── 3-statistical-analysis/     # Tables and intermediate files for statistics
├── resources/                      # MATLAB Project metadata
├── src/
│   ├── 1-trajectory-generation/    # Measurement trajectory generation scripts
│   ├── 2-data-analysis/            # IDS, XL-80, Siemens and comparison workflows
│   │   ├── ids-and-xl/             # IDS / XL-80 preprocessing and feature extraction
│   │   └── nc/                     # Siemens NC/log import and processing
│   ├── 3-statistical-analysis/     # Orthogonal analysis, regression, ANOVA
│   ├── accelerator/                # Python acceleration acquisition prototype
│   └── article-figure/             # Figure scripts for papers and reports
├── start_up.m                      # Add this repository to MATLAB path
├── shut_down.m                     # Remove this repository from MATLAB path
└── position-dependent-dynamic-error-measure.prj
```

Some common functions have already been moved or copied to `../machine-tool-error-core`. New reusable code should be added there first when it is useful to both measurement and prediction workflows.

## Measurement Release Contract

When measurement data is needed by the prediction repository, export a case folder instead of sharing internal scripts. A recommended layout is:

```text
data/releases/adams-comparison/<case-name>/
  measurement_input.mat     # Structured MATLAB data for programmatic reading
  meas_xtraj.txt            # Time and planned/measured axis trajectory for Adams
  meas_endpoint.txt         # Time and measured endpoint displacement
  meas_diff.txt             # Time and endpoint-axis displacement difference
  metadata.mat              # Case name, units, axis, sign convention, source files
```

For existing single-axis Adams comparison cases, the most important files are:

```text
meas_xtraj.txt
meas_endpoint.txt
meas_diff.txt
```

Recommended units:

- Time: second (`s`)
- Displacement for Adams input: meter (`m`) if directly consumed by Adams
- Displacement for measurement analysis: millimeter (`mm`) unless metadata says otherwise

Always record sign conventions in metadata, especially for X/Y direction reversals.

## MATLAB Setup

Open the MATLAB project or run from the repository root:

```matlab
openProject("position-dependent-dynamic-error-measure.prj")
run("start_up.m")
```

If using the adjacent core repository during development:

```matlab
addpath(genpath("../machine-tool-error-core/src"))
```

When done:

```matlab
run("shut_down.m")
```

## Main Workflows

### 1. Trajectory Generation

Trajectory generation scripts are in `src/1-trajectory-generation/`.

Common files:

- `x_trajectory1.m`, `x_trajectory2.m`, `x_trajectory3.m`
- `s_traj_para.m`
- `s_traj_pos.m`
- `s_traj_velo.m`
- `s_traj_acce.m`
- `s_traj_jerk.m`
- `s_traj_len.m`

The S-curve helper functions are shared candidates and should eventually be called from `machine-tool-error-core/src/+mtecore/trajectory`.

### 2. IDS / XL-80 Data Processing

The main measurement processing scripts are in `src/2-data-analysis/ids-and-xl/`.

Typical input data contains:

```matlab
Time
Displacement
```

Typical processing chain:

```text
Raw displacement
  -> positioning error compensation
  -> wavelet denoising
  -> downsampling
  -> velocity and acceleration calculation
  -> peak and segment extraction
  -> dynamic metric tables
```

Detailed module notes are in `src/2-data-analysis/ids-and-xl/README.md`.

### 3. Siemens / NC Data Processing

Siemens import and segmentation scripts are in `src/2-data-analysis/nc/`.

Important functions:

- `functions/load_siemens_data.m`
- `functions/load_folder_siemens_data.m`
- `siemens_data_export.m`
- `siemens_data_segmentation.m`

These scripts extract interpolation, grating-scale displacement, current and torque channels from Siemens export files.

### 4. IDS, Siemens and Interpolation Comparison

`src/article-figure/fig_comparison_ids_siemens.m` compares IDS endpoint displacement, Siemens grating-scale displacement and interpolation data after filtering, geometric compensation and time alignment.

This script currently contains experiment-specific paths and plotting choices. The reusable alignment logic should be factored into `machine-tool-error-core`.

### 5. Statistical Analysis

Statistical scripts live in `src/3-statistical-analysis/`.

Common entries:

- `orthogonal_analysis.m`
- `x_analysis.m`, `x_analysis_same.m`
- `y_analysis.m`, `y_analysis_same.m`
- `uncertainty_analysis.m`
- `demo_orthogonal_analysis.m`

These scripts are measurement-side analysis and should remain in this repository.

## Data Policy

This repository may contain small sample data and processed tables. Large raw measurement datasets should be stored outside Git or managed with a dedicated data release mechanism.

Recommended data levels:

```text
data/raw/          # Optional local raw data, usually ignored
data/processed/    # Optional local intermediate outputs
data/releases/     # Stable outputs consumed by other repositories
```

If a release is used by the prediction repository, treat its format as an interface: avoid changing field names, units or sign conventions without updating the metadata and downstream scripts.

## Dependencies

Main workflows use MATLAB. Depending on the script, the following toolboxes may be required:

- Signal Processing Toolbox
- Wavelet Toolbox
- Curve Fitting Toolbox
- Statistics and Machine Learning Toolbox
- Optimization Toolbox or Global Optimization Toolbox for some filter experiments
- Parallel Computing Toolbox for some optimization experiments

`src/accelerator/accelerator.py` is a Python prototype and is separate from the MATLAB measurement pipeline.

## Notes

- Many scripts are still research scripts and contain absolute paths such as `D:\...`; update paths before running.
- Several scripts assume specific measurement point names, file naming conventions and sign conventions.
- Prefer moving shared utilities to `machine-tool-error-core` before adding new cross-repository dependencies.
- Keep this repository focused on measurement-side truth data and statistical interpretation.

## License

See `LICENSE`.
