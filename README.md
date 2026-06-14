# position-dependent-dynamic-error-measurement

A minimal Python implementation for measuring the position-dependent dynamic error of long-stroke linear machine-tool axes.

## Included workflow

- **Trajectory generation**: creates an out-and-back long-stroke axis command trajectory
- **Data analysis**: computes tracking error statistics (mean, RMSE, max absolute error, standard deviation)
- **Error identification**: bins dynamic error by axis position to identify position-dependent behavior

## Quick usage

```python
from measurement import run_measurement

result = run_measurement(
    stroke_length_mm=1000.0,
    samples_per_stroke=101,
    feed_rate_mm_s=200.0,
    measured_positions_mm=[...],
    bins=20,
)
```

`result` includes `trajectory`, `analysis`, and `position_error_profile`.

## Run tests

```bash
python -m unittest discover -s tests -v
```
