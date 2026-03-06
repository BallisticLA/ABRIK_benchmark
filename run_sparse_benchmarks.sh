#!/bin/bash
#
# Full sparse benchmark suite for ABRIK speed comparisons.
#
# Runs CurlCurl_1 sparse matrix at two submatrix_dim_ratios (0.5 and 1.0) through:
#   - ABRIK:          b_sz = {16, 32} x matmuls = {2, 4, 8, 16, 32, 64}  (12 configs)
#   - ABRIK_adaptive: b_sz = {16, 32}, init=4, incr=4                     (2 configs, auto)
#   - SVDS:           nev = target_rank                                    (1 config)
#   x 5 runs per config
#   No RSVD in sparse benchmark, no GESDD.
#
# Usage:
#   ./run_sparse_benchmarks.sh                   # run full suite
#   ./run_sparse_benchmarks.sh --quick           # quick validation (1 run, fewer params)
#
# Requires: RANDNLA_PROJECT_DIR environment variable (set by RandLAPACK/install.sh)
# Output CSVs go to: <script_dir>/results/
#

set -euo pipefail

# ---- Paths ----
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -z "${RANDNLA_PROJECT_DIR:-}" ]]; then
    echo "ERROR: RANDNLA_PROJECT_DIR is not set."
    echo "Source RandLAPACK's install.sh or add 'export RANDNLA_PROJECT_DIR=...' to ~/.bashrc"
    exit 1
fi

BENCHMARK_BIN="${RANDNLA_PROJECT_DIR}/build/benchmark-build/ABRIK_speed_comparisons_sparse"
OUTPUT_DIR="${SCRIPT_DIR}/results"
MATRIX_DIR="${SCRIPT_DIR}/input_matrices"

# ---- Parameters ----
PRECISION="double"
TARGET_RANK=10

# ABRIK parameters
BLOCK_SIZES=(16 32)
MATMUL_COUNTS=(2 4 8 16 32 64)
NUM_BLOCK_SIZES=${#BLOCK_SIZES[@]}
NUM_MATMUL_SIZES=${#MATMUL_COUNTS[@]}

# Benchmark settings
NUM_RUNS=5
RUN_GESDD=0           # No GESDD
WRITE_MATRICES=0      # Don't write U,V,Sigma files

# Submatrix dimension ratios to run
RATIOS=(0.5 1.0)

# ---- Parse arguments ----
MODE="full"
if [[ "${1:-}" == "--quick" ]]; then
    MODE="quick"
fi

# Quick mode: fewer parameters, single run
if [[ "$MODE" == "quick" ]]; then
    BLOCK_SIZES=(16 32)
    MATMUL_COUNTS=(4 16)
    NUM_BLOCK_SIZES=${#BLOCK_SIZES[@]}
    NUM_MATMUL_SIZES=${#MATMUL_COUNTS[@]}
    NUM_RUNS=1
fi

# ---- Verify prerequisites ----
if [[ ! -x "$BENCHMARK_BIN" ]]; then
    echo "ERROR: benchmark binary not found at $BENCHMARK_BIN"
    echo "Build it with: cd ${RANDNLA_PROJECT_DIR}/build/benchmark-build && cmake --build . --target ABRIK_speed_comparisons_sparse -j\$(nproc)"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# ---- Print plan ----
echo "=========================================="
echo " ABRIK Sparse Benchmark Suite"
echo "=========================================="
echo "Mode:           $MODE"
echo "Precision:      $PRECISION"
echo "Target rank:    $TARGET_RANK"
echo "Num runs:       $NUM_RUNS"
echo "ABRIK configs:  ${NUM_BLOCK_SIZES} block sizes x ${NUM_MATMUL_SIZES} matmul counts = $((NUM_BLOCK_SIZES * NUM_MATMUL_SIZES))"
echo "  block_sizes:  ${BLOCK_SIZES[*]}"
echo "  matmul_counts: ${MATMUL_COUNTS[*]}"
echo "ABRIK adaptive: ${NUM_BLOCK_SIZES} block sizes (init=4, incr=4, auto)"
echo "SVDS:           nev = $TARGET_RANK"
echo "Matrix:         CurlCurl_1.mtx"
echo "Ratios:         ${RATIOS[*]}"
echo "Output dir:     $OUTPUT_DIR"
echo ""

ABRIK_FIXED=$((NUM_BLOCK_SIZES * NUM_MATMUL_SIZES))
ABRIK_ADAPT=${NUM_BLOCK_SIZES}
TOTAL_CONFIGS=$(( (ABRIK_FIXED + ABRIK_ADAPT + 1) * NUM_RUNS ))
echo "Total runs per (matrix, ratio): $TOTAL_CONFIGS"
echo "Total runs overall:             $(( TOTAL_CONFIGS * ${#RATIOS[@]} ))"
echo "=========================================="
echo ""

# ---- Run benchmarks ----
# Sparse CLI:
# <precision> <output_dir> <input> <num_runs> <target_rank> <run_gesdd>
# <write_matrices> <submatrix_dim_ratio> <num_block_sizes> <num_matmul_sizes>
# <block_sizes...> <matmul_sizes...>

MATRIX="${MATRIX_DIR}/CurlCurl_1.mtx"

if [[ ! -f "$MATRIX" ]]; then
    echo "ERROR: Matrix file not found: $MATRIX"
    exit 1
fi

START_TIME=$(date +%s)

for ratio in "${RATIOS[@]}"; do
    echo ">>> Running CurlCurl_1 @ ratio=${ratio} (${MATRIX})..."
    RUN_START=$(date +%s)

    "$BENCHMARK_BIN" \
        "$PRECISION" "$OUTPUT_DIR" "$MATRIX" \
        "$NUM_RUNS" "$TARGET_RANK" "$RUN_GESDD" \
        "$WRITE_MATRICES" "$ratio" \
        "$NUM_BLOCK_SIZES" "$NUM_MATMUL_SIZES" \
        "${BLOCK_SIZES[@]}" "${MATMUL_COUNTS[@]}"

    RUN_END=$(date +%s)
    RUN_ELAPSED=$((RUN_END - RUN_START))
    echo "    CurlCurl_1 @ ratio=${ratio} completed in ${RUN_ELAPSED}s"
    echo ""
done

END_TIME=$(date +%s)
TOTAL_ELAPSED=$((END_TIME - START_TIME))
echo "=========================================="
echo " All sparse benchmarks complete!"
echo " Total time: ${TOTAL_ELAPSED}s ($(( TOTAL_ELAPSED / 60 ))m $(( TOTAL_ELAPSED % 60 ))s)"
echo " Results in: $OUTPUT_DIR"
echo "=========================================="
