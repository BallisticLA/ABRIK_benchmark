#!/bin/bash
#
# Full dense benchmark suite for ABRIK speed comparisons.
#
# Algorithms run (per matrix):
#   - ABRIK:          b_sz = {16, 32} x matmuls = {2, 4, 8, 16, 32, 64}  (12 configs)
#   - ABRIK_adaptive: b_sz = {16, 32}, init=4, incr=4                     (2 configs, auto)
#   - RSVD:           p = {0, 1, 2, 4, 8, 16, 32, 64}                    (8 configs)
#   - SVDS:           nev = target_rank                                    (1 config)
#   x 5 runs per config
#   No GESDD.
#
# Matrices: mat1 (1/j decay) and mat6 (random gapless).
#
# Usage:
#   ./run_dense_benchmarks.sh                    # run default suite (e.g., 10000x10000)
#   ./run_dense_benchmarks.sh --small            # run 2000x2000 suite
#   ./run_dense_benchmarks.sh --quick            # quick validation (1 run, fewer params)
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

BENCHMARK_BIN="${RANDNLA_PROJECT_DIR}/build/benchmark-build/ABRIK_speed_comparisons"
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

# RSVD power iteration values
P_VALUES=(0 1 2 4 8 16 32 64)
NUM_P_VALUES=${#P_VALUES[@]}

# Benchmark settings
NUM_RUNS=5
RUN_GESDD=0   # No GESDD

# ---- Parse arguments ----
MODE="default"
if [[ "${1:-}" == "--small" ]]; then
    MODE="small"
elif [[ "${1:-}" == "--quick" ]]; then
    MODE="quick"
fi

# Quick mode: fewer parameters, single run
if [[ "$MODE" == "quick" ]]; then
    BLOCK_SIZES=(16 32)
    MATMUL_COUNTS=(4 16 64)
    NUM_BLOCK_SIZES=${#BLOCK_SIZES[@]}
    NUM_MATMUL_SIZES=${#MATMUL_COUNTS[@]}
    P_VALUES=(1 4 16 64)
    NUM_P_VALUES=${#P_VALUES[@]}
    NUM_RUNS=1
fi

# ---- Select matrices ----
if [[ "$MODE" == "small" ]]; then
    M=2000
    N=2000
    MATRICES=(
        "${MATRIX_DIR}/2000x2000_rank_2000/ABRIK_test_mat1.txt"
        "${MATRIX_DIR}/2000x2000_rank_2000/ABRIK_test_mat6.txt"
    )
    MATRIX_NAMES=("mat1_2k" "mat6_2k")
elif [[ "$MODE" == "quick" ]]; then
    M=2000
    N=2000
    MATRICES=(
        "${MATRIX_DIR}/2000x2000_rank_2000/ABRIK_test_mat1.txt"
        "${MATRIX_DIR}/2000x2000_rank_2000/ABRIK_test_mat6.txt"
    )
    MATRIX_NAMES=("mat1_2k" "mat6_2k")
else
    # Default: production-scale matrices
    # Update M, N to match your matrix size (e.g., 10000x10000)
    M=10000
    N=10000
    MATRICES=(
        "${MATRIX_DIR}/10000x10000_rank_10000/ABRIK_test_mat1.txt"
        "${MATRIX_DIR}/10000x10000_rank_10000/ABRIK_test_mat6.txt"
    )
    MATRIX_NAMES=("mat1_10k" "mat6_10k")
fi

# ---- Verify prerequisites ----
if [[ ! -x "$BENCHMARK_BIN" ]]; then
    echo "ERROR: benchmark binary not found at $BENCHMARK_BIN"
    echo "Build it with: cd ${RANDNLA_PROJECT_DIR}/build/benchmark-build && cmake --build . --target ABRIK_speed_comparisons -j\$(nproc)"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# ---- Print plan ----
echo "=========================================="
echo " ABRIK Dense Benchmark Suite"
echo "=========================================="
echo "Mode:           $MODE"
echo "Precision:      $PRECISION"
echo "Matrix size:    ${M} x ${N}"
echo "Target rank:    $TARGET_RANK"
echo "Num runs:       $NUM_RUNS"
echo "ABRIK configs:  ${NUM_BLOCK_SIZES} block sizes x ${NUM_MATMUL_SIZES} matmul counts = $((NUM_BLOCK_SIZES * NUM_MATMUL_SIZES))"
echo "  block_sizes:  ${BLOCK_SIZES[*]}"
echo "  matmul_counts: ${MATMUL_COUNTS[*]}"
echo "ABRIK adaptive: ${NUM_BLOCK_SIZES} block sizes (init=4, incr=4, auto)"
echo "RSVD configs:   ${NUM_P_VALUES} p values"
echo "  p_values:     ${P_VALUES[*]}"
echo "SVDS:           nev = $TARGET_RANK"
echo "GESDD:          no"
echo "Matrices:       ${#MATRICES[@]}"
for i in "${!MATRICES[@]}"; do
    echo "  [${MATRIX_NAMES[$i]}] ${MATRICES[$i]}"
done
echo "Output dir:     $OUTPUT_DIR"
echo ""

# Configs per matrix: (ABRIK fixed + ABRIK adaptive + RSVD + SVDS) * NUM_RUNS
ABRIK_FIXED=$((NUM_BLOCK_SIZES * NUM_MATMUL_SIZES))
ABRIK_ADAPT=${NUM_BLOCK_SIZES}
TOTAL_CONFIGS=$(( (ABRIK_FIXED + ABRIK_ADAPT + NUM_P_VALUES + 1) * NUM_RUNS ))
echo "Total runs per matrix: $TOTAL_CONFIGS"
echo "Total runs overall:    $(( TOTAL_CONFIGS * ${#MATRICES[@]} ))"
echo "=========================================="
echo ""

# ---- Run benchmarks ----
START_TIME=$(date +%s)

for i in "${!MATRICES[@]}"; do
    MATRIX="${MATRICES[$i]}"
    NAME="${MATRIX_NAMES[$i]}"

    if [[ ! -f "$MATRIX" ]]; then
        echo "WARNING: Matrix file not found, skipping: $MATRIX"
        continue
    fi

    echo ">>> [$((i+1))/${#MATRICES[@]}] Running ${NAME} (${MATRIX})..."
    MATRIX_START=$(date +%s)

    "$BENCHMARK_BIN" \
        "$PRECISION" "$OUTPUT_DIR" "$MATRIX" \
        "$NUM_RUNS" "$M" "$N" "$TARGET_RANK" "$RUN_GESDD" \
        "$NUM_BLOCK_SIZES" "$NUM_MATMUL_SIZES" "$NUM_P_VALUES" \
        "${BLOCK_SIZES[@]}" "${MATMUL_COUNTS[@]}" "${P_VALUES[@]}"

    MATRIX_END=$(date +%s)
    MATRIX_ELAPSED=$((MATRIX_END - MATRIX_START))
    echo "    ${NAME} completed in ${MATRIX_ELAPSED}s"
    echo ""
done

END_TIME=$(date +%s)
TOTAL_ELAPSED=$((END_TIME - START_TIME))
echo "=========================================="
echo " All benchmarks complete!"
echo " Total time: ${TOTAL_ELAPSED}s ($(( TOTAL_ELAPSED / 60 ))m $(( TOTAL_ELAPSED % 60 ))s)"
echo " Results in: $OUTPUT_DIR"
echo "=========================================="
