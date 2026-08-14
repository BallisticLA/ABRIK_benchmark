# ABRIK_benchmark

Benchmarking companion for [RandLAPACK](https://github.com/BallisticLA/RandLAPACK)'s ABRIK
driver (Adaptive Blocked Randomized Incremental Krylov SVD): speed comparisons, runtime
breakdowns, and accuracy analysis against Spectra SVD and RSVD, on dense and sparse inputs.
The results here back the figures of the ABRIK manuscript.

## How to run

1. **Benchmarks**: [`bench/run_benchmarks.sh`](bench/run_benchmarks.sh) drives the C++
   benchmark binaries built by RandLAPACK (`ABRIK_speed_comparisons`,
   `ABRIK_runtime_breakdown`, `ABRIK_accuracy_analysis`). It requires the
   `RANDNLA_PROJECT_DIR` environment variable set by RandLAPACK's `install.sh`, writes CSVs
   to `results/`, and supports `--quick`. Input matrices are read from `matrices/` (not in
   git; see `.gitignore` for provenance).
2. **Plots**: [`run_all.m`](run_all.m) (MATLAB) reads `results/` and exports 300-dpi PNGs
   to `figures/`. Figure styling is centralized at the top of the script via `groot`
   defaults and cleaned up on exit.

## Repository layout

All BallisticLA benchmark repos share one layout convention (folder roles are fixed; file
names within folders may vary):

| Folder | Role |
|---|---|
| `bench/` | Benchmark-driving code (`run_benchmarks.sh`) |
| `plotting/` | Plotting functions and CSV parsing helpers |
| `results/` | Benchmark output CSVs (tracked: the paper record) |
| `figures/` | Exported figures (not tracked: regenerable via `run_all.m`) |
| `matrices/` | Large input matrices (not tracked; regenerable/downloadable) |
| `utils/` | `generators/` (matrix generation) and `prototypes/` (exploratory scripts) |
| `archive/YYYY-MM-DD-<reason>/` | Retired material (created on first use) |
| `run_all.m` | Plotting entry point |

**Data policy**: `results/` CSVs are tracked in git as the permanent record behind the
paper figures; `figures/` and `matrices/` are regenerable and stay out of git.
