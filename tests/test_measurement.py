import unittest

from measurement import (
    analyze_dynamic_error,
    generate_linear_axis_trajectory,
    identify_position_dependent_error,
    run_measurement,
)


class MeasurementTests(unittest.TestCase):
    def test_generate_linear_axis_trajectory_out_and_back(self):
        trajectory = generate_linear_axis_trajectory(100.0, samples_per_stroke=5, feed_rate_mm_s=50.0)
        positions = [p.position_mm for p in trajectory]
        self.assertEqual(positions, [0.0, 25.0, 50.0, 75.0, 100.0, 75.0, 50.0, 25.0, 0.0])

    def test_analyze_dynamic_error_summary(self):
        result = analyze_dynamic_error([0.0, 10.0, 20.0], [0.2, 9.7, 20.1])
        self.assertAlmostEqual(result.mean_error_mm, 0.0)
        self.assertAlmostEqual(result.max_abs_error_mm, 0.3)

    def test_identify_position_dependent_error_binning(self):
        bins = identify_position_dependent_error([0.0, 10.0, 20.0, 30.0], [0.0, 1.0, 1.0, 2.0], bins=2)
        self.assertEqual(len(bins), 2)
        self.assertAlmostEqual(bins[0].mean_error_mm, 0.5)
        self.assertAlmostEqual(bins[1].mean_error_mm, 1.5)

    def test_run_measurement_full_flow(self):
        measured = [0.1, 9.9, 20.2, 9.8, -0.1]
        result = run_measurement(20.0, samples_per_stroke=3, feed_rate_mm_s=10.0, measured_positions_mm=measured, bins=2)
        self.assertIn("trajectory", result)
        self.assertIn("analysis", result)
        self.assertIn("position_error_profile", result)
        self.assertEqual(len(result["trajectory"]), len(measured))


if __name__ == "__main__":
    unittest.main()
