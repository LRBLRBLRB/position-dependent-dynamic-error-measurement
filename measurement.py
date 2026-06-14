from __future__ import annotations

from dataclasses import dataclass
from math import sqrt
from statistics import mean, pstdev
from typing import Iterable, Sequence


@dataclass(frozen=True)
class TrajectoryPoint:
    time_s: float
    position_mm: float
    velocity_mm_s: float


@dataclass(frozen=True)
class AnalysisResult:
    mean_error_mm: float
    rmse_mm: float
    max_abs_error_mm: float
    std_error_mm: float
    errors_mm: tuple[float, ...]


@dataclass(frozen=True)
class PositionErrorBin:
    position_start_mm: float
    position_end_mm: float
    mean_error_mm: float
    std_error_mm: float
    sample_count: int


def generate_linear_axis_trajectory(
    stroke_length_mm: float,
    samples_per_stroke: int,
    feed_rate_mm_s: float,
) -> tuple[TrajectoryPoint, ...]:
    """Generate an out-and-back trajectory for a long-stroke linear axis."""
    if stroke_length_mm <= 0:
        raise ValueError("stroke_length_mm must be positive")
    if samples_per_stroke < 2:
        raise ValueError("samples_per_stroke must be >= 2")
    if feed_rate_mm_s <= 0:
        raise ValueError("feed_rate_mm_s must be positive")

    dt_s = (stroke_length_mm / feed_rate_mm_s) / (samples_per_stroke - 1)
    forward = tuple(
        TrajectoryPoint(
            time_s=i * dt_s,
            position_mm=i * (stroke_length_mm / (samples_per_stroke - 1)),
            velocity_mm_s=feed_rate_mm_s,
        )
        for i in range(samples_per_stroke)
    )
    backward = tuple(
        TrajectoryPoint(
            time_s=stroke_length_mm / feed_rate_mm_s + i * dt_s,
            position_mm=stroke_length_mm - i * (stroke_length_mm / (samples_per_stroke - 1)),
            velocity_mm_s=-feed_rate_mm_s,
        )
        for i in range(1, samples_per_stroke)
    )
    return forward + backward


def analyze_dynamic_error(
    commanded_positions_mm: Sequence[float],
    measured_positions_mm: Sequence[float],
) -> AnalysisResult:
    """Analyze dynamic tracking errors between commanded and measured axis positions."""
    if len(commanded_positions_mm) != len(measured_positions_mm):
        raise ValueError("commanded_positions_mm and measured_positions_mm must have equal length")
    if not commanded_positions_mm:
        raise ValueError("position arrays must not be empty")

    errors = tuple(measured - command for command, measured in zip(commanded_positions_mm, measured_positions_mm))
    abs_errors = tuple(abs(error) for error in errors)
    mse = mean(tuple(error * error for error in errors))

    return AnalysisResult(
        mean_error_mm=mean(errors),
        rmse_mm=sqrt(mse),
        max_abs_error_mm=max(abs_errors),
        std_error_mm=pstdev(errors) if len(errors) > 1 else 0.0,
        errors_mm=errors,
    )


def identify_position_dependent_error(
    positions_mm: Sequence[float],
    errors_mm: Sequence[float],
    bins: int = 10,
) -> tuple[PositionErrorBin, ...]:
    """Bin errors by axis position to identify position-dependent dynamic behavior."""
    if len(positions_mm) != len(errors_mm):
        raise ValueError("positions_mm and errors_mm must have equal length")
    if not positions_mm:
        raise ValueError("positions_mm must not be empty")
    if bins < 1:
        raise ValueError("bins must be >= 1")

    min_pos = min(positions_mm)
    max_pos = max(positions_mm)
    if min_pos == max_pos:
        return (
            PositionErrorBin(min_pos, max_pos, mean(errors_mm), pstdev(errors_mm) if len(errors_mm) > 1 else 0.0, len(errors_mm)),
        )

    bin_width = (max_pos - min_pos) / bins
    grouped: list[list[float]] = [[] for _ in range(bins)]

    for position, error in zip(positions_mm, errors_mm):
        idx = min(int((position - min_pos) / bin_width), bins - 1)
        grouped[idx].append(error)

    output: list[PositionErrorBin] = []
    for i, group in enumerate(grouped):
        if not group:
            continue
        start = min_pos + i * bin_width
        end = start + bin_width
        output.append(
            PositionErrorBin(
                position_start_mm=start,
                position_end_mm=end,
                mean_error_mm=mean(group),
                std_error_mm=pstdev(group) if len(group) > 1 else 0.0,
                sample_count=len(group),
            )
        )

    return tuple(output)


def run_measurement(
    stroke_length_mm: float,
    samples_per_stroke: int,
    feed_rate_mm_s: float,
    measured_positions_mm: Sequence[float],
    bins: int = 10,
) -> dict[str, object]:
    """Run full position-dependent dynamic error workflow."""
    trajectory = generate_linear_axis_trajectory(stroke_length_mm, samples_per_stroke, feed_rate_mm_s)
    commanded = tuple(point.position_mm for point in trajectory)
    if len(commanded) != len(measured_positions_mm):
        raise ValueError("measured_positions_mm must match generated trajectory length")

    analysis = analyze_dynamic_error(commanded, measured_positions_mm)
    profile = identify_position_dependent_error(commanded, analysis.errors_mm, bins=bins)

    return {
        "trajectory": trajectory,
        "analysis": analysis,
        "position_error_profile": profile,
    }
